package org.binarybrains.bbhealthapp.testrequests.services;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;
import org.binarybrains.bbhealthapp.exception.AppException;
import org.binarybrains.bbhealthapp.testrequests.TestRequest;
import org.binarybrains.bbhealthapp.testrequests.TestRequestRepository;
import org.binarybrains.bbhealthapp.testrequests.consultation.Consultation;
import org.binarybrains.bbhealthapp.testrequests.consultation.ConsultationService;
import org.binarybrains.bbhealthapp.testrequests.consultation.models.CreateConsultationRequest;
import org.binarybrains.bbhealthapp.testrequests.flow.TestRequestFlowService;
import org.binarybrains.bbhealthapp.testrequests.lab.LabResult;
import org.binarybrains.bbhealthapp.testrequests.lab.LabResultService;
import org.binarybrains.bbhealthapp.testrequests.lab.models.CreateLabResult;
import org.binarybrains.bbhealthapp.testrequests.models.RequestStatus;
import org.binarybrains.bbhealthapp.users.User;

import javax.transaction.Transactional;
import javax.validation.Valid;

@Service
@Slf4j
@Validated
public class TestRequestUpdateService {

    @Autowired
    private TestRequestRepository testRequestRepository;


    @Autowired
    private TestRequestFlowService testRequestFlowService;


    @Autowired
    private LabResultService labResultService;


    @Autowired
    private ConsultationService consultationService;


    @Transactional
    public TestRequest saveTestRequest(@Valid TestRequest result) {


        return testRequestRepository.save(result);
    }


    TestRequest updateStatusAndSave(TestRequest testRequest, RequestStatus status) {
        testRequest.setStatus(status);
        return saveTestRequest(testRequest);
    }


    public TestRequest assignForLabTest(Long id, User tester) {
        TestRequest testRequest = testRequestRepository.findByRequestIdAndStatus(id,RequestStatus.INITIATED).orElseThrow(()-> new AppException("Invalid ID"));
        LabResult labResult= labResultService.assignForLabTest(testRequest,tester);
        testRequestFlowService.log(testRequest, RequestStatus.INITIATED, RequestStatus.LAB_TEST_IN_PROGRESS, tester);
        testRequest.setLabResult(labResult);
        return updateStatusAndSave(testRequest, RequestStatus.LAB_TEST_IN_PROGRESS);
    }

    public TestRequest updateLabTest(Long id,@Valid CreateLabResult createLabResult, User tester) {

        TestRequest testRequest = testRequestRepository.findByRequestIdAndStatus(id,RequestStatus.LAB_TEST_IN_PROGRESS).orElseThrow(()-> new AppException("Invalid ID or State"));


        labResultService.updateLabTest(testRequest,createLabResult);
        testRequestFlowService.log(testRequest, RequestStatus.LAB_TEST_IN_PROGRESS, RequestStatus.LAB_TEST_COMPLETED, tester);
        return updateStatusAndSave(testRequest, RequestStatus.LAB_TEST_COMPLETED);
    }

    public TestRequest assignForConsultation(Long id, User doctor) {
        TestRequest testRequest = testRequestRepository.findByRequestIdAndStatus(id,RequestStatus.LAB_TEST_COMPLETED).orElseThrow(()-> new AppException("Invalid ID or State"));
        Consultation consultation =consultationService.assignForConsultation(testRequest,doctor);
        testRequestFlowService.log(testRequest, RequestStatus.LAB_TEST_COMPLETED, RequestStatus.DIAGNOSIS_IN_PROCESS, doctor);
        testRequest.setConsultation(consultation);
        return updateStatusAndSave(testRequest, RequestStatus.DIAGNOSIS_IN_PROCESS);
    }


    public TestRequest updateConsultation(Long id, @Valid CreateConsultationRequest createConsultationRequest, User doctor) {

        TestRequest testRequest = testRequestRepository.findByRequestIdAndStatus(id,RequestStatus.DIAGNOSIS_IN_PROCESS).orElseThrow(()-> new AppException("Invalid ID or State"));
        consultationService.updateConsultation(testRequest,createConsultationRequest);
        testRequestFlowService.log(testRequest, RequestStatus.DIAGNOSIS_IN_PROCESS, RequestStatus.COMPLETED, doctor);
        return updateStatusAndSave(testRequest, RequestStatus.COMPLETED);
    }


}
