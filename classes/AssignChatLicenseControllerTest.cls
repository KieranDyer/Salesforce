@isTest
public class AssignChatLicenseControllerTest
{
    @isTest
	public static void testAssignLicense()
    {
		User u = [SELECT Id, LastName FROM User WHERE IsActive = true AND LastName = 'API' LIMIT 1];
        
        Test.startTest();
        String response = AssignChatLicenseController.invokeApex(u.Id);
        Test.stopTest();
        
        System.assertEquals('You have been assigned a Messaging License.', response);
    }
    
    @isTest
    public static void testBulkAssignment()
    {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Houst - Tier 1 Agent'];
        List<User> us = [SELECT Id, LastName FROM User WHERE IsActive = true AND ProfileId = :p.Id ORDER BY LastLoginDate DESC LIMIT 15];
        
        Test.startTest();
        for (User u : us)
        {
            String response = AssignChatLicenseController.invokeApex(u.Id);
            System.assertEquals('You have been assigned a Messaging License.', response);
            
        }
        Test.stopTest();
    }
    
    @isTest
	public static void testError()
    {        
        Test.startTest();
        String response = AssignChatLicenseController.invokeApex(null);
        Test.stopTest();
        
        System.assertEquals('There has been an error, please contact your administrator.', response);

    }
    
	public static void testLicenseExists()
    {
        PermissionSetLicense permissionSet = [SELECT Id, DeveloperName FROM PermissionSetLicense WHERE DeveloperName = 'LiveMessageUserPsl' LIMIT 1];
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Houst - Tier 1 Agent'];
        User u = [SELECT Name, LastLoginDate 
                  FROM User 
                  WHERE Id NOT IN (SELECT AssigneeId 
                                   FROM PermissionSetLicenseAssign 
                                   WHERE PermissionSetLicenseId = :permissionSet.Id) 
                  AND IsActive=true
                  AND ProfileId = :p.Id
                  LIMIT 1];
        
        PermissionSetLicenseAssign psla = new PermissionSetLicenseAssign();
        psla.AssigneeId = u.Id;
        psla.PermissionSetLicenseId = permissionSet.Id;
        insert psla;
        
        Test.startTest();
        String response = AssignChatLicenseController.invokeApex(u.Id);
        Test.stopTest();
        
        System.assertEquals('You already have a Messaging License.', response);

    }
}