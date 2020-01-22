public class ErrorLog {
    /* 
		A Virtual Class that Defines 
		the structure of a Log.
	*/
    
    public virtual class Log
    {
        public String Type;
        public String ApexClass;
        public String Method;
        
        public String RecordId;
        public String Message;
        public String StackTrace;
    }
    
    /*
		A Class that Extends the Virtual Class - Log
        to define a Log type of Error
    */ 
    public class Error extends Log
    {
        public Error(String cls, String routine, String recId, Exception ex)
        {
            this.Type = 'Error';
            this.ApexClass = cls;
            this.Method = routine;
            this.RecordId = recId;
            this.Message = ex.getMessage();
            this.StackTrace = ex.getStackTraceString();
        }
    }
    
    /*
		A Public Class that can be utilized by other Apex Classes to
		create a record into the ErrorLog sObject stating the Error
	*/
    public void createLog(Log logToCreate)
    {
        /*
        	As we're dealing with errors, we need to ensure that we have not reached
			Governor limits, else this will throw an error itself.
		*/
        if (Limits.getDMLRows() < Limits.getLimitDMLRows() &&
           Limits.getDMLStatements() < Limits.getLimitDMLStatements())
        {
            ErrorLog__c errorLog = new ErrorLog__c(
            	Type__c = logToCreate.Type,
                ApexClass__c = logToCreate.ApexClass,
                Method__c = logToCreate.Method,
                RecordId__c = logToCreate.RecordId,
                Message__c = logToCreate.Message,
                StackTrace__c = logToCreate.StackTrace
            );
            Database.insert(errorLog, false);
        }
        else
        {
            System.debug('The Governor Limits have already been reached and hence failed to create a Log.');
        }
    }

}