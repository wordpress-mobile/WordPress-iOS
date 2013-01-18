package com.divisiblebyzero.xmlrpc;

import javax.swing.UIManager;

import org.apache.log4j.Logger;

import com.divisiblebyzero.xmlrpc.view.XmlRpcServerControlPanel;

class Application {
    private static Logger logger = Logger.getLogger(Application.class);
    
    private Application() {
        new XmlRpcServerControlPanel();
    }
    
    public static void main(String args[]) {
        try {
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        } catch (Exception e) {
            logger.error("Unable to modify application look and feel.");
        }
        
        new Application();
    }
}
