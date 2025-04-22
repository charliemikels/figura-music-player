
-- This script lets other scripts create and use `TL_Futures`, and makes sure each future has an `TL_FutureController` to go with it.
--
-- When using futures, create the future using `require("path/to/futures"):new_future()`,
-- then return the un_finished future to your customer, and give the controller to the async process.

local future_factory = {

    ---Creates a bright future
    ---@return TL_FutureController
    ---@return TL_Future
    new_future = function ()
        local up__is_done = false   ---@type boolean    Flags if this future is done
        local up__error             ---@type string?    Error messages belonging to a failed the future
        local up__value             ---@type any?       The value of a successfull future.
        local up__progress = 0      ---@type number      a number from 0 to 1 to represent a future's progress.
        local up__callback_fns = {} ---@type fun(future:TL_Future)[]    a collection of functions to be called after a future has finished.

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
        ---@class TL_Future
        ---@field is_done fun(self:TL_Future): boolean              Returns false if background process is still running
        ---@field has_error fun(self:TL_Future): boolean            Returns true if an error occured inside the future
        ---@field throw_error fun(self:TL_Future)                   Throws any stored errors.
        ---@field get_error fun(self:TL_Future): any                Returns any stored errors.
        ---@field get_value fun(self:TL_Future): any                Returns any stored values.
        ---@field get_value_or_get_error fun(self:TL_Future): any?  If no errors, return the value. Otherwise, return error as the value.
        ---@field get_value_or_throw_error fun(self:TL_Future): any?  If no errors, return the value. Otherwise, throw the error.
        ---@field register_callback fun(self:TL_Future, fn:fun(future:TL_Future)):TL_Future   Register a function to run after the future is done.
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

            get_value_or_get_error = function(self)
                up__done_or_error()
                if up__value then return up__value end
                if up__error then return up__error end
            end,

            get_value_or_throw_error = function(self)
                up__done_or_error()
                if up__value then return up__value end
                self:throw_error()
            end,

            register_callback = function(self, fn)
                if up__is_done then  -- The future is now. Run callback immediatly
                    fn(self)
                else
                    table.insert(up__callback_fns, fn)
                end
                return self
            end,
        }

        -- Sets future to done, and runs all callbacks. This is sepperate to ensure the script using TL_FutureController allways returns a value or an error.
        local function up__set_done()
            if up__is_done then return end
            up__is_done = true
            for _, callback in ipairs(up__callback_fns) do
                callback(future)
            end
        end

        ---`TL_FutureController`s are paired with a `TL_Future`. The system that returns a future uses the controller to update and fulfill the future.
        ---
        ---@see TL_Future
        ---@class TL_FutureController
        ---@field is_done fun(self:TL_FutureController):boolean Returns the running state of the future. Controll this with `set_done_with_value()` and `set_done_with_error()`
        ---@field set_done_with_value fun(self:TL_FutureController, value:any)
        ---@field set_done_with_error fun(self:TL_FutureController, error:string)
        ---@field set_progress fun(self:TL_FutureController, progress:number)       `Progress` represents the completion of the future.
        ---@field get_future function(self:TL_FutureController)                     Returns the future assosiated with this controller.
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

return future_factory
