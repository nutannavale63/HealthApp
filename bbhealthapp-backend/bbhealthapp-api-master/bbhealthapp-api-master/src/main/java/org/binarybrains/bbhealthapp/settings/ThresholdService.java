package org.binarybrains.bbhealthapp.settings;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.binarybrains.bbhealthapp.exception.AppException;
import org.binarybrains.bbhealthapp.users.UserService;

import java.util.List;

@Service
@Slf4j
public class ThresholdService {


    @Autowired
    UserService userService;

    @Autowired
    TestPositiveCountThresholdRepository testPositiveCountThresholdRepository;


    public TestPositiveCountThreshold update(TestPositiveCountThreshold testPositiveCountThreshold) {
           return testPositiveCountThresholdRepository.save(testPositiveCountThreshold);
    }
    public List<TestPositiveCountThreshold> updateAll(List<TestPositiveCountThreshold> testPositiveCountThresholds) {



            testPositiveCountThresholds.stream()
                   .forEach(testPositiveCountThreshold -> update(testPositiveCountThreshold));

            return findAll();



    }

    public List<TestPositiveCountThreshold> findAll() {

        return testPositiveCountThresholdRepository.findAll();
    }
}
