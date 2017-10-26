/*
* Cody Shepherd
* 'ServerThread.scala'
* */

import java.io.{IOException, PrintStream}
import java.net.{Socket, SocketException}
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
