<#
	.SYNOPSIS
        Initierar sökvägar olika driftmiljöers konfigurationsfiler.

	.DESCRIPTION
        Initierar sökvägar olika driftmiljöers konfigurationsfiler.

    .PARAMETER ConfigReferences
        Spec'ar en hashtable på formatet @{ Miljönamn = Path }
        Där miljönamn är ett hyffsat kort namn utan mellanslag, t.ex Produktion, Test, QA etc
        Path anger en full sökväg till xml-konfigurationen för miljön.
        xml-konfigurationen anger kunder, system etc.

    .PARAMETER Location
        Anger vart denna konfiguration, som pekar ut miljökonfigurationerna, skall sparas.
        Current-Location: Sparar till aktuell sökväg.
        Module-Location: Sparar till modulens sökväg (standard).

	.EXAMPLE
        Initialize-BIFSettings -ConfigReferences @{ Prod = "\\fileserver\share$\BIF\config\production\BIF_production.conf"; Test = "\\fileserver\share$\BIF\config\test\BIF_production.conf";}

	.NOTES

	.LINK
#>
Function Initialize-BIFSettings {
    [cmdletBinding(SupportsShouldProcess=$True, ConfirmImpact="High")]
    Param(
        [Parameter(Mandatory=$True)]
        [hashtable]$ConfigReferences

        ,[Parameter(Mandatory=$False)]
        [ValidateSet('Current-Location','Module-Location')]
        [string]$Location='Module-Location'

        #,[Parameter(Mandatory=$False)]
        #[System.IO.Path]$Path
    )
    
    # Generated with New-FortikaPSFunction

    BEGIN {

        $EnvironmentConfigTemplate=@'
<?xml version="1.0" encoding="UTF-8"?>
<!--
Konfigurationsfil för Lokala säkerhetstjänster.
Här spec'as vårdgivare och system för en viss driftmiljö.

Observera att vissa tecken inte är möjliga att använda i XML.
T.ex &
Om t.ex &-tecken används någonstans så kan det bli rätt mysko felmeddelanden i scripten.

Vårdgivare kan spec'as specifikt för ett visst system.
<System name="" hsaid="">
	<Careproviders>
		<Careprovider name="" hsaid="" />
	</Careproviders>				
</System>

-->
<OLLBIF>
  <Environment>
    <Name>%ENVIRONMENTNAME%</Name>
    <Version>%ENVIRONMENTVERSION%</Version>
    <!-- Dessa templates måste vara i UTF8 -->
    <UserAccessTemplate>%USERTEMPLATEPATH%</UserAccessTemplate>
    <SystemAccessTemplate>%SYSTEMTEMPLATEPATH%</SystemAccessTemplate>
  </Environment>
  <Customers>
    <!--
		<Customer name="">
			<Careproviders>
				<Careprovider name="" hsaid="" />
			</Careproviders>
			<Systems>
				<System name="" hsaid="" />
				<System name="" hsaid="">
				  <Careproviders ExcludeFromUserACL="1">
					<Careprovider name="" hsaid="" />
				  </Careproviders>
				</System>
			</Systems>
		</Customer>
		-->
  </Customers>
</OLLBIF>        
'@


        $SystemACLTemplate=@'
<?xml version='1.0' encoding='UTF-8'?>
<md:EntityDescriptor xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" 
xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" 
xmlns:ds="http://www.w3.org/2000/09/xmldsig#" entityID="%SYSTEMHSAID%" 
xmlns:mdattr="urn:oasis:names:tc:SAML:metadata:attribute">
	<md:Extensions>
		<mdattr:EntityAttributes>
			<saml:Attribute Name="urn:sambi:names:attribute:systemRole">
				<saml:AttributeValue>System</saml:AttributeValue>
			</saml:Attribute>
%SYSTEMACCESSENTRIES%
		</mdattr:EntityAttributes>
	</md:Extensions>
	<md:SPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
		<md:AssertionConsumerService 
		Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://dummy/HTTP-POST" 
		index="1" isDefault="true" />
	</md:SPSSODescriptor>
</md:EntityDescriptor>
'@


        $UserACLTemplate=@'
<resources>

   <!-- ================== S A M T Y C K E ================== -->
   
   <resource id="urn:sambi:names:resource:consent:gui">
      <action id="read">
		 <condition name="urn:sambi:names:attribute:commissionPurpose" value="Vård och behandling"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="read">
		 <condition name="urn:sambi:names:attribute:systemRole" value="BIF;Spärradministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="add">
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Vård och behandling"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="cancel">
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Vård och behandling"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="delete">
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Vård och behandling"/>
         %CAREGIVERXMLDATA%
      </action>
   </resource>
   
   <resource id="urn:sambi:names:resource:consent">
      <action id="read">
		 <condition name="urn:sambi:names:attribute:commissionPurpose" value="Vård och behandling"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="read">
		 <condition name="urn:sambi:names:attribute:systemRole" value="BIF;Spärradministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="add">
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Vård och behandling"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="cancel">
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Vård och behandling"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="delete">
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Vård och behandling"/>
         %CAREGIVERXMLDATA%
      </action>

      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="add">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="cancel">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="delete">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action>
      
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>
      <action id="add">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>
      <action id="cancel">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>
      <action id="delete">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>
   </resource>

   <!-- ================== P A T I E N T R E L A T I O N ================== -->

   <resource id="urn:sambi:names:resource:patientrelation:gui">
      <action id="read">
		 <condition name="urn:sambi:names:attribute:commissionPurpose" value="Vård och behandling"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="read">
		 <condition name="urn:sambi:names:attribute:systemRole" value="BIF;Spärradministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>	  
      <action id="add">
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Vård och behandling"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="cancel">
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Vård och behandling"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="delete">
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Vård och behandling"/>
         %CAREGIVERXMLDATA%
      </action>
   </resource>

   <resource id="urn:sambi:names:resource:patientrelation">
      <action id="read">
		 <condition name="urn:sambi:names:attribute:commissionPurpose" value="Vård och behandling"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="read">
		 <condition name="urn:sambi:names:attribute:systemRole" value="BIF;Spärradministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>	  
      <action id="add">
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Vård och behandling"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="cancel">
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Vård och behandling"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="delete">
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Vård och behandling"/>
         %CAREGIVERXMLDATA%
      </action>
      
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="add">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="cancel">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="delete">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action>
      
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>
      <action id="add">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>
      <action id="cancel">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>
      <action id="delete">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>      
   </resource>

   
   <!-- ================== S P Ä R R ================== -->

   <resource id="urn:sambi:names:resource:block:gui">
      <action id="read">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Spärradministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="add">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Spärradministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="cancel">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Spärradministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="delete">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Spärradministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
   </resource>

   <resource id="urn:sambi:names:resource:block">
      <action id="read">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Spärradministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="add">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Spärradministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="cancel">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Spärradministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="delete">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Spärradministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>

      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="add">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="cancel">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="delete">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action>
      
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>
      <action id="add">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>
      <action id="cancel">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>
      <action id="delete">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>      
   </resource>

   <resource id="urn:sambi:names:resource:block:temprevoke">
      <action id="read">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Spärradministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="add">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Spärradministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="cancel">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Spärradministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="delete">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Spärradministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>

      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="add">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="cancel">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="delete">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action>
      
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>
      <action id="add">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>
      <action id="cancel">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>
      <action id="delete">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>      
   </resource>


     <!-- ================== L O K A L   S P Ä R R ================== -->

   <resource id="urn:sambi:names:resource:local:block:gui">
      <action id="add">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
   </resource>
   

   <!-- ================== L O G ================== -->

   <resource id="urn:sambi:names:resource:log">
      <action id="add">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
      <action id="add">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%
      </action> 
      <action id="read">
            <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
            %CAREGIVERXMLDATA%
        </action>
        <action id="read">
            <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
        </action>	
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>
      <action id="add">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>        
   </resource>
   
   <resource id="urn:sambi:names:resource:logstatus">
      <action id="read">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
      </action>
      
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
      
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>      
   </resource>

   <resource id="urn:sambi:names:resource:logstatus:gui">
      <action id="read">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
   </resource>
   
   <!-- ================== L O G R E P O R T ================== -->

   <resource id="urn:sambi:names:resource:logreport">
		<action id="read">
			<attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Loggadministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%         
      </action>
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
            
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>      
   </resource>
   
    <resource id="urn:sambi:names:resource:logreport:gui">
		<action id="read">
			<attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Loggadministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
   </resource>
   
	<resource id="urn:sambi:names:resource:logreport:status">
      <action id="read">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
      </action>

      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
      
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>      
   </resource>

   <resource id="urn:sambi:names:resource:logreport:status:gui">
      <action id="read">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
    </resource>
   
   <resource id="urn:sambi:names:resource:logreport:info">
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>      
   </resource>


 <!-- ================== L O G R E P O R T   A R K I V S Ö K N I N G ================= -->
   
   <resource id="urn:sambi:names:resource:logreportarchive">
		<action id="read">
			<attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Loggadministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
         %CAREGIVERXMLDATA%         
      </action>
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
            
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>      
   </resource>
   
    <resource id="urn:sambi:names:resource:logreportarchive:gui">
		<action id="read">
			<attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Loggadministratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
   </resource>   
      
   <resource id="urn:sambi:names:resource:logreportarchive:info">
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
   </resource>
   
   <!-- ================== A U T H O R I Z A T I O N ================== -->

   <resource id="urn:sambi:names:resource:authorization:rules">
      <action id="modify">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="read">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
   </resource>
   
   
   <!-- ================== I D P ================== -->

   <resource id="urn:sambi:names:resource:idp">
      <action id="read">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="modify">
			<attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <!--  kolla om detta kan anropas internt-->
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
      <action id="modify">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
   </resource>
   
   <!-- ================== CommissionService ================== -->
   
   <resource id="urn:sambi:names:resource:commission">
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
      </action>
	  <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
      <action id="add">
         <condition name="urn:sambi:names:attribute:systemRole" value="System"/>
      </action>
      <action id="add">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
      
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>
      <action id="add">
         <condition name="urn:sambi:names:attribute:systemRole" value="TP"/>
      </action>      
   </resource>

   <!-- ================== S P ================== -->

   <resource id="urn:sambi:names:resource:sp">
		<action id="read">
			<attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
		<action id="modify">
			<attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <!--  kolla om detta kan anropas internt-->
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
      <action id="modify">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
   </resource>

   <!-- ================== C M ================== -->

   <resource id="urn:sambi:names:resource:cm">
      <action id="read">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="modify">
			<attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <!--  kolla om detta kan anropas internt-->
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
      <action id="modify">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
   </resource>
   
   <!-- ================== S Y S T E M ================== -->

   <resource id="urn:sambi:names:resource:system">
      <action id="read">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="modify">
			<attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <!--  kolla om detta kan anropas internt-->
      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
      <action id="modify">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
   </resource>

   <!-- ================== A R C H I V E ================== -->

   <resource id="urn:sambi:names:resource:archive">
      <action id="archive">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <action id="restore">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
      <!--  kolla om detta kan anropas internt-->
      <action id="archive">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
      <action id="restore">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
   </resource>

  <!-- ================== S T A T I S T I K ================== -->

   <resource id="urn:sambi:names:resource:statistics">
      <action id="read">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>         
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>

      <action id="read">
         <condition name="urn:sambi:names:attribute:systemRole" value="Internal"/>
      </action>
   </resource>
  
   <resource id="urn:sambi:names:resource:statistics:gui">
      <action id="read">
         <attribute name="urn:sambi:names:attribute:systemRole" value="BIF;Administratör"/>           
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Administration"/>
         <attribute name="urn:sambi:names:attribute:commissionPurpose" value="Tillsyn och utvärdering"/>
         %CAREGIVERXMLDATA%
      </action>
   </resource>
</resources>
'@

		# If -debug is set, change $DebugPreference so that output is a little less annoying.
		#	http://learn-powershell.net/2014/06/01/prevent-write-debug-from-bugging-you/
		If ($PSBoundParameters['Debug']) {
			$DebugPreference = 'Continue'
		}


        $ConfigFilename = "OLL.BIF.Utils.conf"


        # check if directories exists
        # check if hashtable keys are without spaces
        # 


        Switch ($Location) {
            "Custom" { 
                $ConfigStoragePath = $Path 
            }
            "Current-Location" {
                #if($Path) {
                #    Throw "Parameter Path can't be used with Location Current-Location"
                #}
                $ConfigStoragePath = (Get-Location).Path
            }
            "Module-Location" {                
                #if($Path) {
                #    Throw "Parameter Path can't be used with Location Module-Location"
                #}
                #$ConfigStoragePath = Split-Path $PSCmdlet.MyInvocation.PSScriptRoot -Parent
                $ConfigStoragePath = Split-Path -Path $PSScriptRoot -Parent
            }
        }

        if(-Not $ConfigStoragePath) {
            Throw "Weops! Could not get ahold of a storage path!"
        }

        # test access to and create config files
        foreach($confname in $ConfigReferences.Keys) {
            #$confname = $_
            $conf = $ConfigReferences[$confname]

            if($(Test-Path -Path $conf) ) {
                Write-Warning "Configuration file `"$conf`" already exists. Not goint to overwrite it!"
            } else {
                # https://stackoverflow.com/questions/9735449/how-to-verify-whether-the-share-has-write-access

                Try {
                    if (-not $(_Test-DirectoryWriteAccess -Path $(Split-Path -Path $conf -Parent) -ErrorAction stop)) { Throw "No access to $conf" }

                    $UserTemplatePath = Join-Path -Path $(Split-Path -Path $conf -Parent) -ChildPath "${confname}_user_template.xml"
                    $SystemTemplatePath = Join-Path -Path $(Split-Path -Path $conf -Parent) -ChildPath "${confname}_system_template.xml"

                    try {
                        $UserACLTemplate | Out-File -FilePath $UserTemplatePath -Encoding utf8 -ErrorAction stop
                        $SystemACLTemplate | Out-File -FilePath $SystemTemplatePath -Encoding utf8 -ErrorAction stop

                        $EnvironmentConfigTemplate | _Expand-VariablesInString -VariableMappings @{
                                                                                        ENVIRONMENTNAME=$confname;
                                                                                        ENVIRONMENTVERSION="x.x";
                                                                                        USERTEMPLATEPATH=$UserTemplatePath;
                                                                                        SYSTEMTEMPLATEPATH=$SystemTemplatePath;
                                                                                } | Out-File -FilePath $conf -Encoding utf8

                    }
                    catch {
                        Throw "Could not create `"{0}`", `"{1}`" or `"{2}`"`r`n{3}" -f $UserTemplatePath, $SystemTemplatePath, $conf, $_.Exception.Message
                    }
                }
                Catch { 
                    # catch here because function _Test-DirectoryWriteAccess uses a validate script that throws an exception
                    Write-Warning "You don't seem to have write access to configuration file `"$conf`". Check that the file exist and you have access rights to it."
                }
            }
        }

        $Overwrite = $True

        $ConfigStoragePath = Join-Path -Path $ConfigStoragePath -ChildPath $ConfigFileName
        if($(Test-Path -Path $ConfigStoragePath)) {
            Write-Warning "$ConfigStoragePath already exists!"
            
            if(-Not $pscmdlet.ShouldProcess("$ConfigStoragePath","Overwrite")) {
                $OverWrite=$False
            }
        } 
        
        if($Overwrite) {
            $ConfigReferences | Export-Clixml -Path $ConfigStoragePath
        } else {
            Write-Verbose "Not writing $ConfigStoragePath"
        }
    }

    PROCESS {
    }

    END {
    }
}
