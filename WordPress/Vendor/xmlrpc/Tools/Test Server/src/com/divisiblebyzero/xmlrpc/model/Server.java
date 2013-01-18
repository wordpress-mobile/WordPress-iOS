package com.divisiblebyzero.xmlrpc.model;

import com.divisiblebyzero.xmlrpc.view.XmlRpcServerControlPanel;

import org.apache.xmlrpc.server.PropertyHandlerMapping;
import org.apache.xmlrpc.server.XmlRpcServer;
import org.apache.xmlrpc.webserver.WebServer;

public class Server {
    private static final int port = 8080;
    private WebServer embeddedWebServer;
    private XmlRpcServer embeddedXmlRpcServer;
    private boolean running;
    private XmlRpcServerControlPanel controlPanel;
    
    public Server(XmlRpcServerControlPanel controlPanel) {
        this.embeddedWebServer = new WebServer(Server.port);
        this.embeddedXmlRpcServer = this.embeddedWebServer.getXmlRpcServer();
        this.running = false;
        this.controlPanel = controlPanel;
        
        PropertyHandlerMapping propertyHandlerMapping = new PropertyHandlerMapping();
        
        try {
            propertyHandlerMapping.load(Thread.currentThread().getContextClassLoader(), "handlers.properties");
        } catch (Exception e) {
            this.controlPanel.addLogMessage(e.getMessage());
        }
        
        this.embeddedXmlRpcServer.setHandlerMapping(propertyHandlerMapping);
    }
    
    public void startEmbeddedWebServer() {
        try {
            this.embeddedWebServer.start();
            
            this.controlPanel.addLogMessage("The XML-RPC server has been started on port " + Server.port + ".");
        } catch (Exception e) {
            this.controlPanel.addLogMessage(e.getMessage());
        }
        
        this.running = true;
    }
    
    public void stopEmbeddedWebServer() {
        try {
            this.embeddedWebServer.shutdown();
            
            this.controlPanel.addLogMessage("The XML-RPC server has been stopped.");
        } catch (Exception e) {
            this.controlPanel.addLogMessage(e.getMessage());
        }
        
        this.running = false;
    }
    
    public boolean isRunning() {
    	return this.running;
    }
}
