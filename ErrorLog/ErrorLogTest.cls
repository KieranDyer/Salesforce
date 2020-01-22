@isTest
public class ErrorLogTest{
    @isTest
    static void createErrorLog(){
        try{
            Integer result = 1 / 0;
        }
        catch(Exception ex){
            new ErrorLog().createLog(
                new ErrorLog.Error(
                    'ErrorLog_Test',
                    'createErrorLog',
                    NULL,
                    ex
                )
            );

            List<ErrorLog__c> logs = [
                SELECT  Id, Type__c, ApexClass__c, Method__c
                FROM    ErrorLog__c
                WHERE   Method__c = 'createErrorLog'
            ];

            System.assertEquals(1, logs.size());
            System.assertEquals('Error', logs.get(0).Type__c);
            System.assertEquals('ErrorLog_Test', logs.get(0).ApexClass__c);
        }
    }
}