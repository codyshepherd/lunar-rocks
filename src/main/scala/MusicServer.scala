/* Cody Shepherd
* socket server prototype
* */

import java.io._
import java.net.{ServerSocket, Socket, SocketException}

import scala.io.BufferedSource

class ServerThread(s: Socket) extends Thread("ServerThread")  {

  override def run() : Unit = {
    try {
      System.out.println("Accepted a Connection from " ++ s.getInetAddress.toString ++ ": " ++ s.getPort.toString)
      val in = new BufferedSource(s.getInputStream()).getLines()
      val out = new PrintStream(s.getOutputStream())

      while (in.hasNext){
        System.out.println(in.next())
        out.println("Ack")
        out.flush()
      }

      System.out.println("Closing Connection.")

      s.close()
    }
    catch {
      case e: SocketException => ()

      case e: IOException =>
        e.printStackTrace()
    }

  }
}

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