import java.util.UUID

import net.liftweb.json._
import net.liftweb.json.Serialization.{read, write}
import Models._


object Test {
  def main(args: Array[String]): Unit = {
    val cID = UUID.randomUUID()
    val mySess = Session(SessionID(1), List(ClientID(cID)),1,
      Track(TrackID(0), ClientID(cID),
        Array(
          Array(0,0,0,0,0,0,0,0),
          Array(0,0,0,0,0,0,0,0),
          Array(0,0,0,0,0,0,0,0),
          Array(0,0,0,0,0,0,0,0),
          Array(0,0,0,0,0,0,0,0),
          Array(0,0,1,0,1,0,0,0),
          Array(0,0,0,0,0,0,0,0),
          Array(0,0,0,0,0,0,0,0),
          Array(0,0,0,0,0,0,0,0),
          Array(0,0,1,0,1,0,0,0),
          Array(0,0,0,0,0,0,0,0),
          Array(0,0,0,0,0,0,0,0),
          Array(1,0,0,0,0,1,1,0),
        )
      )
    )
    val jsonString = Models.jsonString(mySess)
    println(jsonString)

  }
}
