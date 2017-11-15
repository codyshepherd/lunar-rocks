import java.util.UUID
import net.liftweb.json._
import net.liftweb.json.Serialization.{read, write}

case class Track(trackID: TrackID, clientID: ClientID, grid: Array[Array[Int]])
case class Session(sessionID: SessionID, clients: List[ClientID], tempo: Int, board: Track){
  def updateTrack(t: Track): Session = {
    Session(sessionID, clients, tempo, t)
  }
  def newClient(id: ClientID): Option[Session] = {
    clients match{
      case l if l.length >= 2 => None
      case _ => Some(Session(sessionID, id::clients, tempo, board))
    }
  }
}

case class SessionID(id: Int)
case class ClientID(id: UUID)
case class TrackID(id: Int)

object Models {

  def jsonString(t: Track): String = {
    implicit val formats = DefaultFormats
    write(t)
  }

  def jsonString(s: Session): String = {
    implicit val formats = DefaultFormats
    write(s)
  }
}
