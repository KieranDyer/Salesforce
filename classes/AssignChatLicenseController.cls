public without sharing class AssignChatLicenseController 
{
    // Method variables.
    public static Integer licenseCount;
    public static final Integer licenseLimit = 10;
    public static final PermissionSetLicense permissionSet = [SELECT Id, DeveloperName FROM PermissionSetLicense WHERE DeveloperName = 'LiveMessageUserPsl' LIMIT 1];
    public static final PermissionSet messagingPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'Messaging_Agent' LIMIT 1];
    
    @AuraEnabled
    // A handler method for the Lighting Component.
    public static String invokeApex(Id userId)
    {
        if (userId != null)
        {
            // Variables
            List<User> chatUsers = getCurrentChatUsers();
            licenseCount = chatUsers.size();
            List<User> inactiveChatUsers = new List<User>();
            // If limit is not reached, no reason to remove stale agents.
            if (licenseCount < licenseLimit)
            {
                assignMessagingLicense(userId);
                return 'You have been assigned a Messaging License.';
            }
            
            // Logic
            for (User u : chatUsers)
            {
                if (u.Id == userId)
                {
                    return 'You already have a Messaging License.';
                }
                else if (u.LastLoginDate < System.NOW()-1)
                {
                    inactiveChatUsers.add(u);
                }
            }
            
            // If there are any inactive chat users, first remove their permissions.
            if (inactiveChatUsers != null && inactiveChatUsers.size() >0)
            {
                disableInactiveChatUser(inactiveChatUsers[0]);
                licenseCount = licenseCount - inactiveChatUsers.size();
               
                // Then assign the free license to the requesting user.
                if (licenseCount < licenseLimit)
                {
                	assignMessagingLicense(userId);
                    return 'You have been assigned a Messaging License.';
                }
            }
            // If all chat users are active, remove the license of the oldest Login date. 
            else
            {
                disableInactiveChatUser(chatUsers[0]);
                assignMessagingLicense(userId);
                return 'You have been assigned a Messaging License.';
            }
        }
        return 'There has been an error, please contact your administrator.';
    }
    
    // A method to return a list of users that have the ChatUser permission.
    public static List<User> getCurrentChatUsers()
    {
        return [SELECT Name, LastLoginDate 
                FROM User 
                WHERE Id IN (SELECT AssigneeId 
                             FROM PermissionSetLicenseAssign 
                             WHERE PermissionSetLicenseId = :permissionSet.Id) 
                AND IsActive=true
                ORDER BY LastLoginDate ASC];
    }

    // A method that accepts a list of users that have not logged in for 1 day,
    // and removes their ChatUser permissions.
    private static void disableInactiveChatUser(User userToDeactivate)
    {
        if (userToDeactivate != null)
        {
            // Delete Messaging User permission set.
            delete [SELECT AssigneeId
                    FROM PermissionSetAssignment
                    WHERE PermissionSetId = :messagingPermissionSet.Id];
            // Delete Messaging User License.
            delete [SELECT AssigneeId 
                    FROM PermissionSetLicenseAssign 
                    WHERE PermissionSetLicenseId = :permissionSet.Id 
                    AND AssigneeId = :userToDeactivate.Id];
            
            // Delete Chat User permission.
            userToDeactivate.UserPermissionsLiveAgentUser = false;
            update userToDeactivate;
        }
    }
    
    // A method to assign the MessagingUserLicense and LiveAgentUser permission
    // to the user specified in the arguments.
    public static void assignMessagingLicense(Id userId)
    {
        PermissionSetLicenseAssign psla = new PermissionSetLicenseAssign();
        psla.AssigneeId = userId;
        psla.PermissionSetLicenseId = permissionSet.Id;
        Database.insert(psla, true);
        
        Database.update(new User(Id=userId, UserPermissionsLiveAgentUser=true), true);
        
        assignPermissionSet(userId);
    }
    
    // A method to assign the PermissionSet for Messaging API. To be called
    // after assignMessagingLicense.
    private static void assignPermissionSet(Id userId)
    {
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = userId;
        psa.PermissionSetId = messagingPermissionSet.Id;
        Database.insert(psa, true);
    }
}