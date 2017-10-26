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
      val host = s.getInetAddress
      val port = s.getPort
      System.out.println("Accepted a Connection from " ++ host.toString ++ ": " ++ port.toString)
      val in = new BufferedSource(s.getInputStream()).getLines()
      val out = new PrintStream(s.getOutputStream())

      val name = in.next()
      System.out.println("Adding New Player: " ++ name)

      val p = new Player(name, host, port)
      val rid = MusicServer.nextRoomIdSeq
      p.addRoom(rid)
      val r = new Room(rid, p)

      MusicServer.addPlayer(p)
      MusicServer.addRoom(r)

      System.out.println(r.getPlayers.toString())

      out.println("Ack")
      out.flush()

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
