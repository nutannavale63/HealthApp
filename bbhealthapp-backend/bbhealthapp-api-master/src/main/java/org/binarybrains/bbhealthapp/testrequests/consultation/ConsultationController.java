package org.binarybrains.bbhealthapp.testrequests.consultation;


import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.binarybrains.bbhealthapp.config.security.UserLoggedInService;
import org.binarybrains.bbhealthapp.exception.AppException;
import org.binarybrains.bbhealthapp.testrequests.TestRequest;
import org.binarybrains.bbhealthapp.testrequests.consultation.models.CreateConsultationRequest;
import org.binarybrains.bbhealthapp.testrequests.flow.TestRequestFlowService;
import org.binarybrains.bbhealthapp.testrequests.models.RequestStatus;
import org.binarybrains.bbhealthapp.testrequests.services.TestRequestQueryService;
import org.binarybrains.bbhealthapp.testrequests.services.TestRequestUpdateService;
import org.binarybrains.bbhealthapp.users.User;

import javax.validation.ConstraintViolationException;
import java.util.List;

import static org.binarybrains.bbhealthapp.exception.BinaryBrainsResponseStatusException.asBadRequest;
import static org.binarybrains.bbhealthapp.exception.BinaryBrainsResponseStatusException.asConstraintViolation;


@RestController
@RequestMapping("/api/consultations")
public class ConsultationController {

    Logger log = LoggerFactory.getLogger(ConsultationController.class);




    @Autowired
    private TestRequestUpdateService testRequestUpdateService;

    @Autowired
    private TestRequestQueryService testRequestQueryService;


    @Autowired
    TestRequestFlowService  testRequestFlowService;

    @Autowired
    private UserLoggedInService userLoggedInService;



    @GetMapping("/in-queue")
    @PreAuthorize("hasAnyRole('DOCTOR')")
    public List<TestRequest> getForConsultations()  {


        return testRequestQueryService.findBy(RequestStatus.LAB_TEST_COMPLETED);

    }

    @GetMapping
    @PreAuthorize("hasAnyRole('DOCTOR')")
    public List<TestRequest> getForDoctor()  {

        User user = userLoggedInService.getLoggedInUser();
        return testRequestQueryService.findByDoctor(user);


    }



    @PreAuthorize("hasAnyRole('DOCTOR')")
    @PutMapping("/assign/{id}")
    public TestRequest assignForConsultation(@PathVariable Long id) {

        try {
            User user = userLoggedInService.getLoggedInUser();
            TestRequest result = testRequestUpdateService.assignForConsultation(id, user);
          //  log.info(result.toString());
            return result;
          }catch (AppException e) {
            throw asBadRequest(e.getMessage());
        }
    }



    @PreAuthorize("hasAnyRole('DOCTOR')")
    @PutMapping("/update/{id}")
    public TestRequest updateConsultation(@PathVariable Long id,@RequestBody CreateConsultationRequest testResult) {

        try {
            User tester = userLoggedInService.getLoggedInUser();
            TestRequest result = testRequestUpdateService.updateConsultation(id,testResult, tester);
            return result;
        } catch (ConstraintViolationException e) {
            throw asConstraintViolation(e);
        }catch (AppException e) {
            throw asBadRequest(e.getMessage());
        }
    }



}
