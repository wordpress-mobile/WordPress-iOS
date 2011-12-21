package com.divisiblebyzero.xmlrpc.controller;

import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import com.divisiblebyzero.xmlrpc.model.Server;
import com.divisiblebyzero.xmlrpc.view.XmlRpcServerControlPanel;

public class XmlRpcServerControlPanelController implements ActionListener {
    private XmlRpcServerControlPanel controlPanel;
    private Server xmlRpcServer;
    
    public XmlRpcServerControlPanelController(XmlRpcServerControlPanel controlPanel) {
        this.controlPanel = controlPanel;
        this.xmlRpcServer = new Server(this.controlPanel);
    }
    
    public void actionPerformed(ActionEvent actionEvent) {
        String actionCommand = actionEvent.getActionCommand();
        
        if (actionCommand.equals("Start")) {
            this.startXmlRpcServer();
        } else if (actionCommand.equals("Stop")) {
            this.stopXmlRpcServer();
        } else if (actionCommand.equals("Restart")) {
            this.restartXmlRpcServer();
        }
        
        this.controlPanel.refreshControls();
    }
    
    public boolean isXmlRpcServerRunning() {
    	return this.xmlRpcServer.isRunning();
    }
    
    private void startXmlRpcServer() {
        this.controlPanel.addLogMessage("Starting the XML-RPC server.");
        
        this.xmlRpcServer.startEmbeddedWebServer();
    }
    
    private void stopXmlRpcServer() {
        if (this.xmlRpcServer == null) {
            this.controlPanel.addLogMessage("Unable to stop the XML-RPC server, none could be found.");
            
            return;
        }
        
        this.controlPanel.addLogMessage("Stopping the XML-RPC server.");
        
        this.xmlRpcServer.stopEmbeddedWebServer();
    }
    
    private void restartXmlRpcServer() {
        if (this.xmlRpcServer == null) {
            this.controlPanel.addLogMessage("Unable to restart the XML-RPC server, none could be found.");
            
            return;
        }
        
        this.controlPanel.addLogMessage("Restarting the XML-RPC server.");
        
        this.xmlRpcServer.stopEmbeddedWebServer();
        
        this.xmlRpcServer.startEmbeddedWebServer();
    }
}
