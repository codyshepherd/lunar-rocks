import java.net.{InetAddress, Socket}

class Player (name: String, host: InetAddress, port: Int) {
  var rooms: List[Int] = List.empty

  override def toString: String = {
    (name ++ " " ++ host.toString ++ ":" ++ port.toString ++ "\n"
      ++ this.rooms.toString)
  }

  def addRoom(id: Int): Boolean = {
    if (this.rooms.contains(id)){
      false
    }
    else {
      this.rooms = id :: this.rooms
      true
    }
  }
}
