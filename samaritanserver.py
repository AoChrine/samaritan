from twisted.internet.protocol import Protocol, Factory
from twisted.internet import reactor


class IphoneChat(Protocol):
	def connectionMade(self):
		#self.transport.write("""connected""")
		self.factory.clients.append(self)
		print "clients are ", self.factory.clients
	
	def connectionLost(self, reason):
	    self.factory.clients.remove(self)
	
	def dataReceived(self, data):
	    #print "data is ", data
		msg = data
		msg = msg.replace("\n","")
		print msg
		for c in self.factory.clients:
			if (c!=self):
				c.message(msg)
	def message(self, message):
		self.transport.write(message + '\n')


factory = Factory()
factory.protocol = IphoneChat
factory.clients = []

reactor.listenTCP(80, factory)
print "Samaritan socket server is live"
reactor.run()

