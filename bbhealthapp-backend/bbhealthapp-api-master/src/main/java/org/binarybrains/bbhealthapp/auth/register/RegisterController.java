package org.binarybrains.bbhealthapp.auth.register;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;
import org.binarybrains.bbhealthapp.exception.AppException;
import org.binarybrains.bbhealthapp.users.User;

import static org.binarybrains.bbhealthapp.exception.BinaryBrainsResponseStatusException.asBadRequest;

@RestController
public class RegisterController {



    private RegisterService registerService;


    private static final Logger log = LoggerFactory.getLogger(RegisterController.class);


    @Autowired
    public RegisterController( RegisterService userService) {

        this.registerService = userService;
    }


    @RequestMapping(value = {"/auth/newuser", "/api/master/auth/newuser"}, method = RequestMethod.POST)
    public User saveUser(@RequestBody RegisterRequest user) {
        try {
            return registerService.addUser(user);
        } catch (AppException e) {
            throw   asBadRequest(e.getMessage());
        }
    }


    @RequestMapping(value = {"/auth/newdoctor", "/api/master/auth/newdoctor"}, method = RequestMethod.POST)
    public User saveDoctor(@RequestBody RegisterRequest user) {

        try {
            return registerService.addDoctor(user);
        } catch (AppException e) {
            throw asBadRequest(e.getMessage());
        }
    }


    @RequestMapping(value = {"/auth/newtester", "/api/master/auth/newtester"}, method = RequestMethod.POST)
    public User saveTester(@RequestBody RegisterRequest user) {

        try {
            return registerService.addTester(user);
        } catch (AppException e) {
            throw asBadRequest(e.getMessage());
        }
    }
}
