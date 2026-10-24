package org.binarybrains.bbhealthapp.config.loaddata;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;
import org.binarybrains.bbhealthapp.documents.DocumentService;
import org.binarybrains.bbhealthapp.settings.TestPositiveCountThreshold;
import org.binarybrains.bbhealthapp.settings.ThresholdService;
import org.binarybrains.bbhealthapp.settings.ThresholdType;
import org.binarybrains.bbhealthapp.testrequests.TestRequest;
import org.binarybrains.bbhealthapp.testrequests.authority.models.UpdateApprovalRequest;
import org.binarybrains.bbhealthapp.testrequests.consultation.ConsultationService;
import org.binarybrains.bbhealthapp.testrequests.consultation.models.CreateConsultationRequest;
import org.binarybrains.bbhealthapp.testrequests.consultation.models.DoctorSuggestion;
import org.binarybrains.bbhealthapp.testrequests.lab.LabResultService;
import org.binarybrains.bbhealthapp.testrequests.lab.models.CreateLabResult;
import org.binarybrains.bbhealthapp.testrequests.lab.models.TestStatus;
import org.binarybrains.bbhealthapp.testrequests.models.CreateTestRequest;
import org.binarybrains.bbhealthapp.testrequests.services.TestRequestCreateService;
import org.binarybrains.bbhealthapp.testrequests.services.TestRequestQueryService;
import org.binarybrains.bbhealthapp.testrequests.services.TestRequestUpdateService;
import org.binarybrains.bbhealthapp.users.User;
import org.binarybrains.bbhealthapp.users.UserService;
import org.binarybrains.bbhealthapp.users.models.AccountStatus;
import org.binarybrains.bbhealthapp.users.roles.RoleService;
import org.binarybrains.bbhealthapp.users.roles.UserRole;

import javax.transaction.Transactional;
import java.util.ArrayList;
import java.util.List;

import static org.binarybrains.bbhealthapp.config.loaddata.DataGenerator.*;
import static org.binarybrains.bbhealthapp.shared.FileReader.getMultipartFileFrom;
import static org.binarybrains.bbhealthapp.shared.FileReader.readFromClassPath;


@Component
public class AppInitializationService implements ApplicationListener<ApplicationReadyEvent> {


    @Autowired
    RoleService roleService;

    @Autowired
    UserService userService;

    @Autowired
    TestRequestCreateService testRequestCreateService;

    @Autowired
    TestRequestQueryService testRequestQueryService;

    @Autowired
    TestRequestUpdateService testRequestUpdateService;

    @Autowired
    LabResultService labResultService;

    @Autowired
    ConsultationService consultationService;

    @Autowired
    ThresholdService thresholdService;

    @Autowired
    DocumentService documentService;

    @Value("${app.testrun}")
    public boolean isTestRun = false;

    List<User> allUsers = new ArrayList<>();
    List<User> allDoctors = new ArrayList<>();
    List<User> allTesters = new ArrayList<>();
    User defaultDoctor = null;
    User defaultTester = null;
    User govtAuthority = null;
    private static final Logger log = LoggerFactory.getLogger(AppInitializationService.class);



    @Override
    public void onApplicationEvent(ApplicationReadyEvent event) {

        if (isTestRun == false && roleService.shouldInitialize()) {
            initialize();
        }


    }

    public void initialize() {
        initDataGenerator();
        log.info("Loading Default Values Please wait");
        addDefaultRoles();
        addDefaultThresholds();

        addDefaultUsersAndTestRequest();


        log.info("Loaded all Default Values");
    }


    @Transactional
    public void addDefaultRoles() {

        roleService.saveRoleFor(UserRole.USER);
        roleService.saveRoleFor(UserRole.TESTER);
        roleService.saveRoleFor(UserRole.DOCTOR);
        roleService.saveRoleFor(UserRole.GOVERNMENT_AUTHORITY);

    }

    @Transactional
    public void addDefaultThresholds() {


        thresholdService.update(createThreshold(ThresholdType.RED, 18));
        thresholdService.update(createThreshold(ThresholdType.YELLOW, 10));
        thresholdService.update(createThreshold(ThresholdType.GREEN, 5));

    }

    public TestPositiveCountThreshold createThreshold(ThresholdType thresholdType, int maxLimit) {
        TestPositiveCountThreshold testPositiveCountThreshold = new TestPositiveCountThreshold();
        testPositiveCountThreshold.setThresholdType(thresholdType);
        testPositiveCountThreshold.setMaxLimit(maxLimit);
        return testPositiveCountThreshold;
    }


    public void addDefaultUsersAndTestRequest() {


        addDefaultUserData();

        loadLotsOfUserData();

        addUnverifiedUsers();


    }

    public void addDefaultUserData() {

        allUsers.add(createUserFrom("user", getRandomPinCode()));
        allUsers.add(createUserFrom("userB", getRandomPinCode()));
        allUsers.add(createUserFrom("userC", getRandomPinCode()));
        allUsers.add(createUserFrom("userD", getRandomPinCode()));


        defaultDoctor = userService.addDoctor(createRegisterRequestWith("doctor", getRandomPinCode()));
        allDoctors.add(defaultDoctor);
        allDoctors.add(userService.addDoctor(createRegisterRequestWith("doctorA", getRandomPinCode())));


        defaultTester = userService.addTester(createRegisterRequestWith("tester", getRandomPinCode()));
        allTesters.add(defaultTester);
        allTesters.add(userService.addTester(createRegisterRequestWith("testerA", getRandomPinCode())));
        govtAuthority = userService.addGovernmentAuthority(createRegisterRequestWith("authority", getRandomPinCode()));

        approveAll(allDoctors);
        approveAll(allTesters);
    }

    void addUnverifiedUsers() {

        createUnVerifiedDoctor("doctorunknown", "id-1.png");
        createUnVerifiedDoctor("doctoranotherUnknown", "id-2.png");


        createUnVerifiedTester("testerUnknown", "id-1.png");
        createUnVerifiedTester("testeranotherUnknown", "id-2.png");


    }

    private User createUnVerifiedDoctor(String unknownDoctor, String fileName) {
        User doctor = userService.addDoctor(createRegisterRequestWith(unknownDoctor, getRandomPinCode()));
        MultipartFile result = getMultipartFileFrom(fileName);
        documentService.save(doctor.getId(), result);
        return doctor;
    }

    private User createUnVerifiedTester(String unknownTester, String fileName) {
        User tester = userService.addTester(createRegisterRequestWith(unknownTester, getRandomPinCode()));
        MultipartFile result = getMultipartFileFrom(fileName);
        documentService.save(tester.getId(), result);
        return tester;
    }


    public UpdateApprovalRequest createApprovalRequestFor(User user) {
        UpdateApprovalRequest updateApprovalRequest = new UpdateApprovalRequest();
        updateApprovalRequest.setUserId(user.getId());
        updateApprovalRequest.setStatus(AccountStatus.APPROVED);
        return updateApprovalRequest;
    }


    public List<TestData> getAllData() {

        try {

            String settingsFileContent = readFromClassPath("test-data.json");
            ObjectMapper mapper = new ObjectMapper();
            mapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
            return mapper.readValue(settingsFileContent, new TypeReference<List<TestData>>() {
            });

        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }


    }


    public void approveAll(List<User> users) {


        users.stream()
                .map(this::createApprovalRequestFor)
                .forEach(this.userService::updateApprovalStatus);
    }

    public void loadLotsOfUserData() {


        List<TestData> allUsers = getAllData();//.subList(0,3);

        // log.info(allUsers.toString());
        allUsers.forEach(input -> {

            //log.info("current User"  + input.toString());
            User updatedUser = createUserFrom(input.getName(), input.getPincode());
            // log.info("updatedUser User"  + updatedUser.toString());
            TestRequest testRequest = createTestRequestsForUser(input, updatedUser);

            //log.info(testRequest.toString());

        });


    }

    public TestRequest createTestRequestsForUser(TestData input, User updatedUser) {
        TestRequest testRequest = createTestRequestFrom(updatedUser);
        User tester = defaultTester;
        User approvedDoctor = defaultDoctor;
        if (input.canAssignForLabTest()) {
            testRequestUpdateService.assignForLabTest(testRequest.getRequestId(), tester);

            if (input.canUpdateLabTest()) {


                testRequestUpdateService.updateLabTest(testRequest.getRequestId(), createLabResultWith(input, updatedUser), tester);


                if (input.canAssignConsultation()) {

                    testRequestUpdateService.assignForConsultation(testRequest.getRequestId(), approvedDoctor);

                    if (input.canCompleteTest()) {

                        testRequestUpdateService.updateConsultation(testRequest.getRequestId(), createConsultationRequestWith(input, updatedUser), approvedDoctor);
                    }

                }


            }


        }
        return testRequest;
    }





    public User createUserFrom(String name, Integer pincode) {
        return userService.addUser(createRegisterRequestWith(name, pincode));
    }

    private CreateConsultationRequest createConsultationRequestWith(TestData input, User updatedUser) {
        CreateConsultationRequest createConsultationRequest = new CreateConsultationRequest();


        if (input.isTestPositive()) {
            if (input.canAdmit()) {
                createConsultationRequest.setComments("should admit as high bp");
                createConsultationRequest.setSuggestion(DoctorSuggestion.ADMIT);
            } else {
                createConsultationRequest.setComments("can home quarantine");
                createConsultationRequest.setSuggestion(DoctorSuggestion.HOME_QUARANTINE);
            }
        } else {
            createConsultationRequest.setComments("No Issues");
            createConsultationRequest.setSuggestion(DoctorSuggestion.NO_ISSUES);
        }

        return createConsultationRequest;
    }

    private CreateLabResult createLabResultWith(TestData input, User updatedUser) {
        CreateLabResult createLabResult = new CreateLabResult();

        if (input.isTestPositive()) {

            createLabResult.setResult(TestStatus.POSITIVE);
            if (input.canAdmit()) {
                createLabResult.setBloodPressure("190/120");
                createLabResult.setComments("high Bp");
                createLabResult.setHeartBeat("140/200");
                createLabResult.setOxygenLevel("120-130");
                createLabResult.setTemperature("108");
            } else {
                createLabResult.setBloodPressure("130/90");
                createLabResult.setComments("Asymptomatic");
                createLabResult.setHeartBeat("90/95");
                createLabResult.setOxygenLevel("90-95");

                createLabResult.setTemperature("102");
            }

        } else {
            createLabResult.setBloodPressure("130/90");
            createLabResult.setComments("Normal");
            createLabResult.setHeartBeat("90/95");
            createLabResult.setOxygenLevel("90-95");
            createLabResult.setResult(TestStatus.NEGATIVE);
            createLabResult.setTemperature("97");
        }

        return createLabResult;
    }


    TestRequest createTestRequestFrom(User updatedUser) {
        CreateTestRequest createTestRequest = new CreateTestRequest();
        createTestRequest.setAge(getRandomAge());
        createTestRequest.setPhoneNumber(updatedUser.getPhoneNumber());
        createTestRequest.setEmail(updatedUser.getEmail());
        createTestRequest.setPinCode(updatedUser.getPinCode());
        createTestRequest.setName(updatedUser.getFirstName());
        createTestRequest.setGender(updatedUser.getGender());
        createTestRequest.setAddress(updatedUser.getAddress());


        TestRequest testRequestFrom = testRequestCreateService.createTestRequestFrom(updatedUser, createTestRequest);

        //  log.info("created test request " + testRequestFrom.toString());
        return testRequestFrom;
    }







}

