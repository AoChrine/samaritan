from twisted.internet.protocol import Factory, Protocol
from twisted.internet import reactor

class ChatServer(Protocol):
	def Connected(self):
		self.getConnection.clients.append(self)
		print "clients are ", self.getConnection.clients

	def notConnected(self, reason):
		self.getConnection.clients.remove(self)

	def dataReceived(self, data):
		splitText = data.split(':')
		wordOne = splitText.pop([0])
                wordTwo = splitText.pop([0])
		print wordOne
                print wordTwo
                #print splitText
		if len(splitText) > 1:
			command = splitText[0]
			content = splitText[1]

			msg = ""
			if (command == "user"):
				self.name = content
				msg = self.name + " has joined"

			elif (command == "msg"):
				msg = self.name + ": " + content
				print msg

			for c in self.getConnection.clients:
				c.message(msg)

	def message(self, message):
		self.transport.write(message + '\n')

getConnection = Factory()
getConnection.protocol = ChatServer
getConnection.clients = []
reactor.listenTCP(80, getConnection)
print "server is up and running"
reactor.run()


