
-- In order to make the music player work at low permission levels, much of its logic, needs to be spread out over time.
--
-- Futures help us keep track of these long-running opperations, and let the caller use callback-style asyncronous programming.
--
-- (That callback feature is also why we defined a new `TL_Futures` type. Figura already has a built in `Future` type.)
--
-- The new_future function returns a TL_FutureController and a TL_Future. When writing a function that returns a future,
-- keep a hold of the controller for internal use, and give the TL_Future to your consumer.

---@generic T
---@class TL_FuturesAPI
---@field new_future fun(type_of_value:`T`, catch_for_colon_syntax:nil):TL_FutureController<T>,TL_Future<T>     Creates a future and captures the type information
local tl_futures_api = {

    new_future = function(type_of_value, catch_for_colon_syntax)
        if type(type_of_value) == "table" and type_of_value.new_future then
            -- caller probably used `:` syntax, which means `type_of_value` is actualy `self`. Let's help them out and try the 2nd paramiter.
            type_of_value = catch_for_colon_syntax
        end
        if type(type_of_value) ~= "string" then error("Please pass a type (as a string) when creating a future.") end

        local up__type_of_value = type_of_value       ---@type string     Marks what type the future is expected to contain.
        local up__is_done = false   ---@type boolean    Flags if this future is done
        local up__error             ---@type string?    Error messages belonging to a failed the future
        local up__value             ---@type any?       The value of a successfull future.
        local up__progress = 0      ---@type number      a number from 0 to 1 to represent a future's progress.
        local up__callback_fns = {} ---@type fun(future:TL_Future)[]    a collection of functions to be called after a future has finished.
        local up__completed_callbacks = 0 ---@type integer  a tracker for completed callbacks. Used to keep track of ran callbacks, so that they are guarrentied to run in order.

        local function up__done_or_error()
            if not up__is_done then error("Future is not done") end
        end



        ---Futures store the state of an async process. When the process is done, a value or an error can be extracted from the future.
        ---
        ---Most fields in the future expect the future to be done before they get read. Allways check `:is_done()` before reading values,
        ---or use `:register_callback()` to queue up a function to run immediatly when the future finishes.
        ---
        ---(Dev note: The "Future" type already sorta exist in Figura (see the networking/HTTP module),
        ---but I really wanted a callback functions to make chaining easier, so I'm defining my own type.)
        ---@class TL_Future<T>
        ---@field is_done fun(self:TL_Future): boolean              Returns false if background process is still running
        ---@field get_progress fun(self:TL_Future): number          Returns a number from 0 to 1 (or whatever the value of "progress" is)
        ---@field has_error fun(self:TL_Future): boolean            Returns true if an error occured inside the future
        ---@field throw_error fun(self:TL_Future)                   Throws any stored errors.
        ---@field get_error fun(self:TL_Future): string?            Returns any stored errors.
        ---@field get_value fun(self:TL_Future): T                  Returns any stored values.
        ---@field get_expected_value_type fun(self:TL_Future): string   Returns the expected type of the value. Can be ran before future is done.
        ---@field get_value_or_get_error fun(self:TL_Future): T|string  If no errors, return the value. Otherwise, return error as the value.
        ---@field get_value_or_throw_error fun(self:TL_Future): T?  If no errors, return the value. Otherwise, throw the error.
        ---@field register_callback fun(self:TL_Future<T>, fn:fun(future:TL_Future<T>)):TL_Future<T>   Register a function to run after the future is done.
        local future = {
            is_done = function(self)
                return up__is_done
            end,

            get_progress = function(self)
                if up__is_done then return 1 end
                return up__progress
            end,

            has_error = function(self)
                up__done_or_error()
                if up__error then return true end
                return false
            end,

            get_error = function(self)
                up__done_or_error()
                return up__error
            end,

            throw_error = function(self)
                if self:has_error() then error(up__error) end
                error("Throw_error had no error to throw")
            end,

            get_value = function(self)
                up__done_or_error()
                return up__value
            end,

            get_expected_value_type = function(self)
                return up__type_of_value
            end,

            get_value_or_get_error = function(self)
                up__done_or_error()
                if up__value then return up__value end
                return up__error
            end,

            get_value_or_throw_error = function(self)
                up__done_or_error()
                if up__value then return up__value end
                self:throw_error()
            end,

            register_callback = function(self, fn)
                table.insert(up__callback_fns, fn)
                if up__is_done and #up__callback_fns == up__completed_callbacks+1 then  -- +1 because we just added a new item to the list.
                    -- The future is done, and all previous callbacks have been ran. Restart a new callback cycle
                    -- TODO: Sanity check this. Does it actualy work with late callbacks? multiple late callbacks?
                    while #up__callback_fns > up__completed_callbacks do
                        local callback_fn = up__callback_fns[up__completed_callbacks + 1]
                        callback_fn(self)
                        up__completed_callbacks = up__completed_callbacks +1
                    end
                end
                return self
            end,
        }

        -- Sets future to done, and runs all callbacks. This is sepperate to ensure the script using TL_FutureController allways returns a value or an error.
        local function up__set_done()
            if up__is_done then return end
            up__is_done = true
            while #up__callback_fns > up__completed_callbacks do
                local callback_fn = up__callback_fns[up__completed_callbacks + 1]
                callback_fn(future)
                up__completed_callbacks = up__completed_callbacks +1
            end
        end

        ---`TL_FutureController`s are paired with a `TL_Future`. The system that returns a future uses the controller to update and fulfill the future.
        ---
        ---@see TL_Future
        ---@class TL_FutureController<T>
        ---@field is_done fun(self:TL_FutureController):boolean Returns the running state of the future. Controll this with `set_done_with_value()` and `set_done_with_error()`
        ---@field set_done_with_value fun(self:TL_FutureController, value:T)
        ---@field set_done_with_error fun(self:TL_FutureController, error:string)
        ---@field set_progress fun(self:TL_FutureController, progress:number)       `Progress` is a number from 0-1 that represents the completion of the future.
        ---@field get_future fun(self:TL_FutureController):TL_Future<T>              Returns the future assosiated with this controller.
        local future_controller = {
            is_done = function(self) return up__is_done end,
            set_done_with_value = function(self, value) up__value = value; up__set_done(); end,
            set_done_with_error = function(self, error) up__error = error; up__set_done(); end,
            set_progress = function(self, progress) up__progress = progress end,
            get_future = function(self) return future end
        }

        return future_controller, future
    end
}

return tl_futures_api
