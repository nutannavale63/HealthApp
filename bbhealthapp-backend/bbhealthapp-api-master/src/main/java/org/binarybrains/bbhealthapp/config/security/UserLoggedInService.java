package org.binarybrains.bbhealthapp.config.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;
import org.binarybrains.bbhealthapp.users.User;
import org.binarybrains.bbhealthapp.users.UserService;


@Component
public class UserLoggedInService {

    private UserService userService;

    @Autowired
    public UserLoggedInService(UserService userService) {
        this.userService = userService;
    }


    public User getLoggedInUser() {
            UserDetails principal = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
            return userService.findByUserName(principal.getUsername());

    }


}
