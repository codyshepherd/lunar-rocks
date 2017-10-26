import MusicServer.RoomId

class Room (id: RoomId, firstPlayer: Player){

  private var players : List[Player] = List(firstPlayer)
  private var num_players : Int = players.length

  def addPlayer(p: Player): Boolean = {
    if (num_players < MusicServer.MAX_PLAYERS) {
      players = p :: players
      true
    }
    else false
  }

  def getPlayers: List[Player] = players

  def getNumPlayers: Int = num_players
}
