
File processors are in charge of 

First, processors need to recognize songs based of file path. This works with the Library system, to find a list of processable songs. 

Secondly, and chiefly, it converts the a file from the Files API into a Song. This is typicaly a very expensive process instruction-wise. By leveraging the world-render event, processors are able to work as hard as they want, and then let go occasionaly to let the game to catch up and prevents timeouts. (This doesn't work with the Tick events, btw, because Minecraft will notice if it missed a tick event, and will delay everything so that it can catch up.)
