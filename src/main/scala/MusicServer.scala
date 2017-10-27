import akka.NotUsed
import akka.actor._
import akka.http.scaladsl._
import akka.http.scaladsl.server.Directives._
import akka.http.scaladsl.model.ws.{BinaryMessage, Message, TextMessage}
import akka.http.scaladsl.model.{HttpRequest, HttpResponse}
import akka.stream._
import akka.stream.scaladsl._
import scala.io.StdIn

/* Cody Shepherd
* 'MusicServer.scala'
* */


class MusicServer {

  implicit val system = ActorSystem()
  implicit val materializer = ActorMaterializer()

  val greeterWebSocketService =
    Flow[Message]
        .collect {
          case tm: TextMessage => TextMessage(Source.single("Echoing ") ++ tm.textStream)
          //case bm: BinaryMessage =>
          //  bm.dataStream.runWith(Sink.ignore)
        }

  val route =
    path("lobby") {
      get {
        handleWebSocketMessages(greeterWebSocketService)
      }
    }

  val bindingFuture = Http().bindAndHandle(route, "localhost", 8080)

  println(s"Server online at http://localhost:8080/\nPress RETURN to stop...")
  StdIn.readLine()

  import system.dispatcher // for the future transformations (???)
  bindingFuture
      .flatMap(_.unbind()) // trigger unbinding from the port
        .onComplete(_ => system.terminate()) // and shutdown when done
}

object Main {
  def main(args: Array[String]): Unit = {
    val m = new MusicServer()
  }
}