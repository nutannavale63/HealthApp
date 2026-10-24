package org.binarybrains.bbhealthapp.auth;

import io.swagger.annotations.Api;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;
import org.binarybrains.bbhealthapp.auth.models.LoginRequest;
import org.binarybrains.bbhealthapp.auth.models.LoginResponse;
import org.binarybrains.bbhealthapp.auth.register.RegisterRequest;
import org.binarybrains.bbhealthapp.config.security.TokenProvider;
import org.binarybrains.bbhealthapp.documents.Document;
import org.binarybrains.bbhealthapp.exception.AppException;
import org.binarybrains.bbhealthapp.users.User;
import org.binarybrains.bbhealthapp.users.UserService;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import static org.binarybrains.bbhealthapp.exception.BinaryBrainsResponseStatusException.asBadRequest;

@RestController
public class AuthController {


    private AuthenticationManager authenticationManager;

    private TokenProvider tokenProvider;

    private UserService userService;


    private static final Logger log = LoggerFactory.getLogger(AuthController.class);



    @Autowired
    public AuthController(AuthenticationManager authenticationManager, TokenProvider tokenProvider, UserService userService) {
        this.authenticationManager = authenticationManager;
        this.tokenProvider = tokenProvider;
        this.userService = userService;
    }

    @GetMapping({"/auth/validate/{userId}", "/api/master/auth/validate/{userId}"})
    public ResponseEntity<?> validateUserId(@PathVariable Long userId){
        User user = userService.findById(userId).get();
        if(user != null){
            return ResponseEntity.ok(true);
        }else{
            return ResponseEntity.ok(false);
        }
    }

    @GetMapping({"/auth/validateusername/{username}/{email}/{phone}", "/api/master/auth/validateusername/{username}/{email}/{phone}"})
    public ResponseEntity<?> validateUserDetails(@PathVariable String username,@PathVariable String email,@PathVariable String phone){
        User user = userService.findByUserName(username);
        user = userService.findByEmail(email);
        user = userService.findByPhoneNumber(phone);
        if(user != null){
            return ResponseEntity.ok(true);
        }else{
            return ResponseEntity.ok(false);
        }
    }

    @GetMapping({"/auth/pendingUsers", "/api/master/auth/pendingUsers"})
    public ResponseEntity<?> getPendingUserList(){
        List<User> users = userService.findPendingApprovals();
        Set<Long> userIdSet = new HashSet<>();
        for(User user : users){
            userIdSet.add(user.getId());
        }
        return ResponseEntity.ok(userIdSet);
    }

    @RequestMapping(value = {"/auth/greetings", "/api/master/auth/greetings"}, method = RequestMethod.GET)
    public ResponseEntity<?> greetings()  {

        return ResponseEntity.ok("Hello Sir");
    }


    @RequestMapping(value = {"/auth/login", "/api/master/auth/login"}, method = RequestMethod.POST)
    public ResponseEntity<?> login(@RequestBody LoginRequest loginRequest) throws AuthenticationException {

        try {

            final Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            loginRequest.getUserName(),
                            loginRequest.getPassword()
                    )
            );


            if(userService.isApprovedUser( loginRequest.getUserName()) == false){
                throw new AppException("User Not Approved");
            }



            SecurityContextHolder.getContext().setAuthentication(authentication);
            final String token = tokenProvider.generateToken(authentication);
            LoginResponse result = new LoginResponse(loginRequest.getUserName(), "Success", token);

            return ResponseEntity.ok(result);


        } catch (AppException e) {

            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN, e.getMessage(), e);
        }catch (AuthenticationException e) {
            e.printStackTrace();
            log.info("AuthenticationException" + e.getMessage());
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN, "Bad credentials", e);
        }

    }

}
