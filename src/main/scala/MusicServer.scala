/* Cody Shepherd
* 'MusicServer.scala'
* */

import java.net.ServerSocket

object MusicServer {
  def main(args: Array[String]) : Unit = {
    try {
      var conns = 0
      val listener = new ServerSocket(1002)
      while(true){
        new ServerThread(listener.accept()).start()
        conns += 1
        System.out.println("Connections: " ++ conns.toString)
      }
      listener.close()
    }
  }
}