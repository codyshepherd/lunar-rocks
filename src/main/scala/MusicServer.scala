/* Cody Shepherd
* 'MusicServer.scala'
* */

import java.net.ServerSocket
import java.util.concurrent.ConcurrentLinkedQueue

import org.slf4j.Logger
import org.slf4j.LoggerFactory

import scala.collection.mutable

object MusicServer {
  type RoomId = Int
  val MAX_PLAYERS = 2

  private var roomIdQueue: mutable.Queue[Int] = mutable.Queue.empty
  private var roomIdSeq : Int = 0

  private var playerList : List[Player] = List.empty
  private var roomList : List[Room] = List.empty

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

  def addPlayer(p: Player): Boolean = {
    this.playerList = p :: this.playerList
    true
  }

  def addRoom(r: Room): Boolean = {
    this.roomList = r :: this.roomList
    true
  }

  def nextRoomIdSeq: Int = {
    if (roomIdQueue.isEmpty) {
      val id = roomIdSeq
      roomIdSeq += 1
      return id
    }
    else roomIdQueue.dequeue()
  }
}