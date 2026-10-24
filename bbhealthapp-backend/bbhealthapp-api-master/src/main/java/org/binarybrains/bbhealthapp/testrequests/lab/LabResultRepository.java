package org.binarybrains.bbhealthapp.testrequests.lab;

import org.springframework.data.jpa.repository.JpaRepository;
import org.binarybrains.bbhealthapp.testrequests.TestRequest;
import org.binarybrains.bbhealthapp.users.User;

import java.util.List;
import java.util.Optional;


public interface LabResultRepository extends JpaRepository<LabResult,Long> {


	Optional<LabResult> findByresultId(Long id);

	void deleteByresultId(Long id);
	
	List<LabResult> findByTester(User user);
	Optional<LabResult> findByTesterAndRequest(User user,TestRequest testRequest);
	Optional<LabResult> findByRequest(TestRequest request);


}
