import java.util.UUID

import scala.collection.immutable.HashMap

case class Controller(maxsess: Int) {

  val MAXCLIENTSESSIONS: Int = maxsess


  var clients = HashMap.empty[UUID, String]
  var sessions = HashMap.empty[SessionID, Session]
  var clientSessions = HashMap.empty[ClientID, List[SessionID]]


  def getAllClients = Seq(clients)

  def addClient(id: UUID, nick: String): Boolean = {
    clients.get(id) match {
      case None => {
        clients = clients + (id -> nick)
        true
      }
      case Some(a) => false
    }
  }

  def removeClient(id: UUID): Boolean = {
    clients.get(id) match {
      case None => false
        clients = clients - id
        true
    }
  }

  def trackUpdate(id: SessionID, t: Track): Boolean = {
    val session = sessions.get(id)
    session match {
      case None => false
      case Some(s) =>
        sessions = sessions - id + (id -> s.updateTrack(t))
        true
    }
  }

  def clientJoin(sid: SessionID, cid: ClientID): Boolean = {
    val session = sessions.get(sid)
    session match {
      case None => false
      case Some(s) =>
        val newsess = s.newClient(cid)
        newsess match {
          case None => false
          case Some(sess) =>
            sessions = sessions - sid + (sid -> sess)
            true
        }
    }
  }

  def getSession(id: SessionID): Option[Session] = {
    sessions.get(id)
  }
}

object controllerTest {
  def main(args: Array[String]): Unit = {
    val c = Controller(5)
    println(c.getAllClients)
    val id = UUID.randomUUID()
    println(c.addClient(id, "first"))
    println(c.addClient(id, "second"))
    println(c.addClient(UUID.randomUUID(), "third"))
    println(c.getAllClients)
    println(c.removeClient(UUID.randomUUID()))
    println(c.removeClient(id))
    println(c.getAllClients)
  }
}