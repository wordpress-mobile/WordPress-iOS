# The XML-RPC Test Server

The XML-RPC test server is written in Java and utilizes the Apache XML-RPC server library. This test server can be useful when debugging problems with the XML-RPC framework.

# Usage

To start the server simply call Ant from the XML-RPC test server directory:

    $ ant <target>

This will invoke Ant with the default target. The default target will issue the following targets in the following order, the last target is the default invoked by Ant:

  - init
  - compile
  - pre-jar
  - jar
  - run

These targets each play a role in building and running the Java project. The details of each target can be found in the Ant build script.

Finally, the XML-RPC test server should now be running. To start the server simply click on the "Start" button. This will start the test server on port 8080, available for any incoming XML-RPC requests.

## Creating XML-RPC server handlers

The XML-RPC test server exposes XML-RPC methods through server handlers. Each server handler is simply a Java class that is registered with the Apache XML-RPC library. Here is an example of the Echo handler provided in the distribution:

    public class Echo {
        public String echo(String message) {
            return message;
        }
    }

This handler simply takes a message provided in the XML-RPC request and returns it in the XML-RPC response. To register this handler with the XML-RPC server simply add it to the propertyHandlerMapping in Server.java:

    try {
        propertyHandlerMapping.addHandler("Echo", Echo.class);

        this.embeddedXmlRpcServer.setHandlerMapping(propertyHandlerMapping);
    } catch (Exception e) {
        this.controlPanel.addLogMessage(e.getMessage());
    }

The handler is now available to any incoming XML-RPC requests.

# License

Copyright (c) 2012 Eric Czarny.

The Cocoa XML-RPC Framework should be accompanied by a LICENSE file, this file contains the license relevant to this distribution.

If no LICENSE exists please contact Eric Czarny <eczarny@gmail.com>.
