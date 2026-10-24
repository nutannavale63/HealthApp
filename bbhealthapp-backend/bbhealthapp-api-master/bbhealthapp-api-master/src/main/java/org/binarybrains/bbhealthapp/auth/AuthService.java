package org.binarybrains.bbhealthapp.auth;

import org.binarybrains.bbhealthapp.auth.models.LoginRequest;
import org.binarybrains.bbhealthapp.auth.models.LoginResponse;
import org.binarybrains.bbhealthapp.config.security.TokenProvider;
import org.binarybrains.bbhealthapp.users.UserService;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

@Service
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final TokenProvider tokenProvider;
    private final UserService userService;

    public AuthService(AuthenticationManager authenticationManager, TokenProvider tokenProvider, UserService userService) {
        this.authenticationManager = authenticationManager;
        this.tokenProvider = tokenProvider;
        this.userService = userService;
    }

    public LoginResponse login(LoginRequest request) {
        try {
            UsernamePasswordAuthenticationToken authenticationToken = 
                new UsernamePasswordAuthenticationToken(request.getUserName(), request.getPassword());
            
            Authentication authentication = authenticationManager.authenticate(authenticationToken);
            
            if (!userService.isApprovedUser(request.getUserName())) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "User Not Approved");
            }
            
            String token = tokenProvider.generateToken(authentication);
            
            return new LoginResponse(request.getUserName(), "Success", token);
        } catch (BadCredentialsException e) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid Credentials");
        }
    }
}
