package org.binarybrains.bbhealthapp;

import lombok.extern.log4j.Log4j2;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.ApplicationPidFileWriter;

import java.io.File;

@SpringBootApplication
@Log4j2
public class BbhealthappApplication {

	public static void main(String[] args) {


		//SpringApplication.run(BbhealthappApplication.class, args);

		String fileName = System.getProperty("user.home") + File.separator + "bbhealthappApp.pid";
		SpringApplication application = new SpringApplication(BbhealthappApplication.class);
		log.info("Updated Process Id is available on " + fileName);
		application.addListeners(new ApplicationPidFileWriter(fileName));
		application.run();
	}  


}
