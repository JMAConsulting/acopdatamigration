
ALTER TABLE civicrm_contact ADD column IF NOT Exists OrgID int unsigned DEFAULT NULL COMMENT 'Org ID from AOCP database';
ALTER TABLE civicrm_contact ADD column IF NOT EXISTS IndividualID int unsigned DEFAULT NULL COMMENT 'individual id from ACOP Database';
ALTER TABLE civicrm_contact ADD UNIQUE INDEX ui_individualid(`IndividualID`);

/*Process churches*/
INSERT INTO civicrm_contact (contact_type, contact_sub_type, external_identifier, sort_name, organization_name, display_name, OrgID)
SELECT 'Organization', CONCAT(UNHEX('01'), 'New_Church', UNHEX('01')), if(PINorEnvelope = '', NULL, PINorEnvelope), Name, Name, Name, OrgID
FROM acop_org_data.Orgs
WHERE (Level = 'Churches' OR Level = 'Non-ACOP Church/Charity' OR STATUS like '%Church%') AND STATUS != 'ACOP Affiliated Church' AND level != 'District/Other ACOP';

INSERT INTO civicrm_value_church_minist_2 (entity_id, church_ministry_type_8) 
SELECT cc.id, 1 
FROM acop_org_data.Orgs o
INNER JOIN civicrm_contact cc ON cc.OrgID = o.OrgID
WHERE STATUS = 'Partnership' AND Level = 'Churches';

INSERT INTO civicrm_value_church_minist_2 (entity_id, church_ministry_type_8) 
SELECT cc.id, 3 
FROM acop_org_data.Orgs o
INNER JOIN civicrm_contact cc ON cc.OrgID = o.OrgID
WHERE STATUS = 'ACOP Associated Church' AND ( Level = 'Churches' OR level = 'HEAD');

INSERT INTO civicrm_value_church_minist_2 (entity_id, church_ministry_type_8) 
SELECT cc.id, 4 
FROM acop_org_data.Orgs o
INNER JOIN civicrm_contact cc ON cc.OrgID = o.OrgID
WHERE (STATUS = 'Non-ACOP Church' AND Level = 'Churches') OR (STATUS = 'Non-ACOP Church') OR (STATUS = 'Patnership' AND Level = 'Head');

INSERT INTO civicrm_contact (contact_type, contact_sub_type, external_identifier, sort_name, display_name, organization_name, OrgID)
SELECT 'Organization', CONCAT(UNHEX('01'), 'Ministry', UNHEX('01')), ReferenceName, Name, Name, Name, OrgID
FROM acop_org_data.Orgs
WHERE STATUS = 'Non-ACOP Camp' OR Status LIKE '%Ministry%' OR STATUS = 'AWM Account';

INSERT INTO civicrm_value_church_minist_2 (entity_id, church_ministry_type_8) 
SELECT cc.id, 6 
FROM acop_org_data.Orgs o
INNER JOIN civicrm_contact cc ON cc.OrgID = o.OrgID
WHERE STATUS = 'Non-ACOP Camp';

INSERT INTO civicrm_value_church_minist_2 (entity_id, church_ministry_type_8) 
SELECT cc.id, 7 
FROM acop_org_data.Orgs o
INNER JOIN civicrm_contact cc ON cc.OrgID = o.OrgID
WHERE (STATUS = 'ACOP Associated Ministry' OR STATUS = 'AWM Account');

INSERT INTO civicrm_contact (contact_type, contact_sub_type, external_identifier, sort_name, display_name, organization_name, OrgID)
SELECT 'Organization', CONCAT(UNHEX('01'), 'Foundation', UNHEX('01')), ReferenceName, Name, Name, Name, OrgID
FROM acop_org_data.Orgs
WHERE STATUS = 'Donor';

/*Process Mailing Addresses*/
CREATE TEMPORARY TABLE org_addresses
SELECT cc.id as contact_id, o.OrgAddress1 as street_address, o.OrgAddress2 as supplemental_address_1, o.OrgCity as city, sp.id as state_province_id, c.id as country_id, o.OrgZIPCode as postal_code, 3 as location_type_id ,1 as is_primary, 0 as is_billing
FROM acop_org_data.Orgs o
INNER JOIN civicrm_contact cc ON cc.OrgID = o.OrgId
INNER JOIN civicrm_country c ON c.name = o.OrgCountry
INNER JOIN civicrm_state_province sp ON sp.abbreviation = o.OrgState AND sp.country_id = c.id;

INSERT INTO civicrm_address (contact_id, street_address, supplemental_address_1, city, state_province_id, country_id, postal_code, location_type_id, is_primary, is_billing)
SELECT contact_id, street_address, supplemental_address_1, city, state_province_id, country_id, postal_code, location_type_id, is_primary, is_billing
FROM org_addresses;

DROP TABLE org_addresses;

/*Proces Meeting Addresses*/
CREATE TEMPORARY TABLE org_addresses
SELECT cc.id as contact_id, o.OrgAddress1 as street_address, o.OrgAddress2 as supplemental_address_1, o.OrgCity as city, sp.id as state_province_id, c.id as country_id, o.OrgZIPCode as postal_code, 1 as location_type_id ,0 as is_primary, 1 as is_billing
FROM acop_org_data.Orgs o
INNER JOIN civicrm_contact cc ON cc.OrgID = o.OrgId 
INNER JOIN civicrm_country c ON c.name = o.MeetingCountry
INNER JOIN civicrm_state_province sp ON sp.abbreviation = o.MeetingState AND sp.country_id = c.id;

INSERT INTO civicrm_address (contact_id, street_address, supplemental_address_1, city, state_province_id, country_id, postal_code, location_type_id, is_primary, is_billing)
SELECT contact_id, street_address, supplemental_address_1, city, state_province_id, country_id, postal_code, location_type_id, is_primary, is_billing
FROM org_addresses;

DROP TABLE org_addresses;
/*Populate Websites*/
CREATE TEMPORARY TABLE org_websites
SELECT cc.id as contact_id, o.WebAddress as url, 1 as website_type_id
FROM acop_org_data.Orgs o
INNER JOIN civicrm_contact cc ON cc.OrgID = o.OrgId 
WHERE o.WebAddress !='';

INSERT INTO civicrm_website (contact_id, url, website_type_id)
SELECT contact_id, url, website_type_id
FROM org_websites;

DROP TABLE org_websites;

CREATE TEMPORARY TABLE org_websites
SELECT cc.id as contact_id, p.Phone as url, 1 as website_type_id
FROM acop_org_data.Orgs o
INNER JOIN civicrm_contact cc ON cc.OrgID = o.OrgId 
INNER JOIN acop_org_data.Phones p ON p.OrgID = o.OrgID
WHERE p.Type = 'W';

INSERT INTO civicrm_website (contact_id, url, website_type_id)
SELECT contact_id, url, website_type_id
FROM org_websites;

DROP TABLE org_websites;

/*Populate Phones*/
CREATE TEMPORARY TABLE org_phones
SELECT DISTINCT cc.id as contact_id, o.OrgOfficePhone as phone, 1 as phone_type_id, 3 as location_type_id, 1 as is_primary
FROM acop_org_data.Orgs o
INNER JOIN civicrm_contact cc ON cc.OrgID = o.OrgId
WHERE o.OrgOfficePhone != '';

INSERT INTO civicrm_phone (contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT contact_id, phone, phone_type_id, location_type_id, is_primary
FROM org_phones;

DROP TABLE org_phones;

/*Process mobiles*/
CREATE TEMPORARY TABLE org_phones
SELECT cc.id as contact_id, p.Phone as phone, 2 as phone_type_id, 4 as location_type_id, 0 as is_primary
FROM acop_org_data.Orgs o
INNER JOIN civicrm_contact cc ON cc.OrgID = o.OrgId 
INNER JOIN acop_org_data.Phones p ON p.OrgID = o.OrgID
WHERE p.Type = 'P' AND p.Description = 'Mobile';

INSERT INTO civicrm_phone (contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT contact_id, phone, phone_type_id, location_type_id, is_primary
FROM org_phones;

DROP TABLE org_phones;
/*Process Other Phones*/
CREATE TEMPORARY TABLE org_phones
SELECT cc.id as contact_id, p.Phone as phone, 1 as phone_type_id, 4 as location_type_id, 1 as is_primary
FROM acop_org_data.Orgs o
INNER JOIN civicrm_contact cc ON cc.OrgID = o.OrgId 
INNER JOIN acop_org_data.Phones p ON p.OrgID = o.OrgID
WHERE p.Type = 'P' AND p.Description = 'Other Home';

INSERT INTO civicrm_phone (contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT contact_id, phone, phone_type_id, location_type_id, is_primary
FROM org_phones;

DROP TABLE org_phones;
/*Process Other Phones*/
CREATE TEMPORARY TABLE org_phones
SELECT cc.id as contact_id, p.Phone as phone, 1 as phone_type_id, 4 as location_type_id, 1 as is_primary
FROM acop_org_data.Orgs o
INNER JOIN civicrm_contact cc ON cc.OrgID = o.OrgId 
INNER JOIN acop_org_data.Phones p ON p.OrgID = o.OrgID
WHERE p.Type = 'P' AND p.Description = 'Business';

INSERT INTO civicrm_phone (contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT contact_id, phone, phone_type_id, location_type_id, is_primary
FROM org_phones;

DROP TABLE org_phones;
/*Process Faxes*/
CREATE TEMPORARY TABLE org_phones
SELECT cc.id as contact_id, p.Phone as phone, 1 as phone_type_id, 4 as location_type_id, 1 as is_primary
FROM acop_org_data.Orgs o
INNER JOIN civicrm_contact cc ON cc.OrgID = o.OrgId 
INNER JOIN acop_org_data.Phones p ON p.OrgID = o.OrgID
WHERE p.Type = 'P' AND p.Description = 'Fax';

INSERT INTO civicrm_phone (contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT contact_id, phone, phone_type_id, location_type_id, is_primary
FROM org_phones;

DROP TABLE org_phones;

INSERT INTO civicrm_note (entity_table, entity_id, note, subject) 
SELECT 'civicrm_contact', cc.id, o.Notes, 'Notes from People Database'
FROM acop_org_data.Orgs o
INNER JOIN civicrm_contact cc ON cc.OrgID = o.OrgId 
WHERE o.Notes != '';

CREATE TEMPORARY TABLE org_data
SELECT cc.id as entity_id, o.EnvelopeNumber as envelope_number_9, o.CRARegistrationNumber as cra_registration_number_10, if(o.EffectiveDate != '', DATE_FORMAT(STR_TO_DATE(o.EffectiveDate, '%m/%d/%Y'), '%Y-%m-%d'), NULL) as cra_registration_effective_date_12
FROM acop_org_data.Orgs o
INNER JOIN civicrm_contact cc ON cc.OrgID = o.OrgId;

INSERT INTO civicrm_value_organization__3 (entity_id, envelope_number_9, cra_registration_number_10, cra_registration_effective_date_12)
SELECT entity_id, envelope_number_9, cra_registration_number_10, cra_registration_effective_date_12 FROM org_data;

/*Process Individuals / start with the head of households*/
INSERT INTO civicrm_contact (last_name, first_name, middle_name, nick_name, gender_id, birth_date, prefix_id, suffix_id, contact_type, IndividualID, sort_name, display_name)
SELECT p.LastName, p.FirstName, if(p.MiddleName != '', p.MiddleName, NULL), if(p.GoesByName != '', p.GoesByName, NULL), gov.value, if(p.DateofBirth != '', DATE_FORMAT(STR_TO_DATE(p.DateOfBirth, '%m/%d/%Y'), '%Y-%m-%d'), NULL), pov.value, sov.value, 'Individual', p.IndividualID, CONCAT(p.LastName, ', ', p.FirstName), CONCAT(p.Title, ' ', p.FirstName, ' ', p.LastName, ' ', p.Suffix)
FROM acop_data.People p
LEFT JOIN civicrm_option_value gov ON gov.label = p.Gender AND gov.option_group_id = 3
LEFT JOIN civicrm_option_value pov ON pov.label = if(p.Title = 'Miss', 'Miss.', if(p.Title = 'Pastor', 'Pastor.', p.Title)) AND pov.option_group_id = 6
LEFT JOIN civicrm_option_value sov ON sov.label = if(p.Suffix = 'Sr', 'Sr.', if(p.Suffix = 'Jr', 'Jr.', p.Suffix)) AND sov.option_group_id = 7
WHERE IndividualNumber = 1;

CREATE TEMPORARY TABLE ind_data
SELECT cc.id as entity_id, if(p.IndDateCredentials != '', p.IndDateCredentials, NULL) as date_credentialed_13, if(p.IndAnniversary != '', p.IndAnniversary, NULL) as anniversary_14, if(p.IndOrdained != '', p.IndOrdained, NULL) as ordained_15, if(p.IndCommenced != '', p.IndCommenced, NULL) as commenced_16, if(p.IndApplicationDate != '', p.IndApplicationDate, NULL) as application_date_17
FROM acop_data.People p
INNER JOIN civicrm_contact cc On cc.IndividualID = p.IndividualID;

INSERT INTO civicrm_value_individual_ad_4(entity_id, date_credentialed_13, anniversary_14, ordained_15, commenced_16, application_date_17)
SELECT entity_id, date_credentialed_13, anniversary_14, ordained_15, commenced_16, application_date_17 
FROM ind_data;

DROP TABLE ind_data;

CREATE TEMPORARY TABLE ind_data
SELECT cc.id as entity_id, if(p.IndEducation != '', p.IndEducation, NULL) as education_completed_20, 1 as head_of_family_21, IF(p.IndStatus != '', p.IndStatus, NULL) as status_24, IF(p.IndMarriageRegistration != '', p.IndMarriageRegistration, NULL) as marriage_registration_25
FROM acop_data.People p
INNER JOIN civicrm_contact cc On cc.IndividualID = p.IndividualID;

INSERT INTO civicrm_value_individual_ad_6 (entity_id, education_completed_20, head_of_family_21, status_24, marriage_registration_25) 
SELECT entity_id, education_completed_20, head_of_family_21, status_24, marriage_registration_25
FROM ind_data;

DROP TABLE ind_data;

CREATE TEMPORARY TABLE ind_address
SELECT cc.id as contact_id, p.Address1 as street_address, p.Address2 as supplemental_address_1, p.City as city, sp.id as state_province_id, c.id as country_id, p.ZIPCode as postal_code, 3 as location_type_id, 1 as is_primary, 1 as is_billing
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID 
LEFT JOIN civicrm_country c ON c.name = p.Country
LEFT JOIN civicrm_state_province sp ON sp.abbreviation = p.State AND sp.country_id = c.id;

INSERT INTO civicrm_address(contact_id, street_address, supplemental_address_1, city, state_province_id, country_id, postal_code, location_type_id, is_primary, is_billing)
SELECT contact_id, street_address, supplemental_address_1, city, state_province_id, country_id, postal_code, location_type_id, is_primary, is_billing
FROM ind_address;

DROP TABLE ind_address;

CREATE TABLE ind_emails
SELECT cc.id as contact_id, e.EmailAddr as email, 3 as location_type_id, 1 as is_primary
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Emails e ON e.FamilyNumber = p.FamilyNumber and e.IndividualNumber = p.IndividualNumber
WHERE e.Description = 'Preferred E-mai'
AND e.EmailUnlisted = 'False';

INSERT INTO ind_emails (contact_id, email, location_type_id, is_primary)
SELECT cc.id, e.EmailAddr, 6, 1
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Emails e ON e.FamilyNumber = p.FamilyNumber and e.IndividualNumber = p.IndividualNumber
WHERE e.Description = 'Preferred E-mai'
AND e.EmailUnlisted = 'True';

INSERT INTO ind_emails (contact_id, email, location_type_id, is_primary)
SELECT cc.id, e.EmailAddr, 3, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Emails e ON e.FamilyNumber = p.FamilyNumber and e.IndividualNumber = p.IndividualNumber
INNER JOIN acop_data.Emails ee ON ee.FamilyNumber = p.FamilyNumber and ee.IndividualNumber = p.IndividualNumber
WHERE e.Description = 'E-mail'
AND ee.Description = 'Preferred E-mai'
AND e.EmailAddr != ee.EmailAddr
AND e.EmailUnlisted = 'False';

INSERT INTO ind_emails (contact_id, email, location_type_id, is_primary)
SELECT cc.id, e.EmailAddr, 6, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Emails e ON e.FamilyNumber = p.FamilyNumber and e.IndividualNumber = p.IndividualNumber
INNER JOIN acop_data.Emails ee ON ee.FamilyNumber = p.FamilyNumber and ee.IndividualNumber = p.IndividualNumber
WHERE e.Description = 'E-mail'
AND ee.Description = 'Preferred E-mai'
AND e.EmailAddr != ee.EmailAddr
AND e.EmailUnlisted = 'False';

INSERT INTO ind_emails (contact_id, email, location_type_id, is_primary)
SELECT cc.id, e.EmailAddr, 2, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Emails e ON e.FamilyNumber = p.FamilyNumber and e.IndividualNumber = p.IndividualNumber
WHERE e.Description = 'Business'
AND e.EmailUnlisted = 'False';

INSERT INTO ind_emails (contact_id, email, location_type_id, is_primary)
SELECT cc.id, e.EmailAddr, 4, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Emails e ON e.FamilyNumber = p.FamilyNumber and e.IndividualNumber = p.IndividualNumber
WHERE (e.Description = 'Email 2' OR e.Description = 'Assistant email')
AND e.EmailUnlisted = 'False';

INSERT INTO ind_emails (contact_id, email, location_type_id, is_primary)
SELECT cc.id, e.EmailAddr, 6, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Emails e ON e.FamilyNumber = p.FamilyNumber and e.IndividualNumber = p.IndividualNumber
WHERE (e.Description = 'Email 2' OR e.Description = 'Assistant email')
AND e.EmailUnlisted = 'TRUE';

INSERT INTO civicrm_email (contact_id, email, location_type_id, is_primary)
SELECT contact_id, email, location_type_id, is_primary
FROM ind_emails;

DROP TABLE ind_emails;

CREATE TEMPORARY TABLE ind_phones (
 `contact_id` int unsigned DEFAULT NULL,
 `phone` varchar(255),
 `phone_type_id` int unsigned DEFAULT NULL,
 `location_type_id` int unsigned DEFAULT NULL,
 `is_primary` int unsigned DEFAULT 0
);

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id as contact_id, p.PreferredPhone as phone, 1 as phone_type_id, 3 as location_type_id, 1 as is_primary
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID;

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, p.HomePhone, 1, 3, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
WHERE p.HomePhoneUnlisted = 'FALSE';

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, p.HomePhone, 1, 6, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
WHERE p.HomePhoneUnlisted = 'TRUE';

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, ph.Phone, 1, 3, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Phones ph ON ph.FamilyNumber = p.FamilyNumber AND p.IndividualNumber = ph.IndividualNumber
WHERE ph.Type = 'P' AND ph.Description = 'Business' AND ph.Unlisted = 'False';

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, ph.Phone, 1, 6, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Phones ph ON ph.FamilyNumber = p.FamilyNumber AND p.IndividualNumber = ph.IndividualNumber
WHERE ph.Type = 'P' AND ph.Description = 'Business' AND ph.Unlisted = 'True';

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, ph.Phone, 1, 4, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Phones ph ON ph.FamilyNumber = p.FamilyNumber AND p.IndividualNumber = ph.IndividualNumber
WHERE ph.Type = 'P' AND ph.Description = 'Other Home' AND ph.Unlisted = 'False';

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, ph.Phone, 1, 6, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Phones ph ON ph.FamilyNumber = p.FamilyNumber AND p.IndividualNumber = ph.IndividualNumber
WHERE ph.Type = 'P' AND ph.Description = 'Other Home' AND ph.Unlisted = 'True';

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, ph.Phone, 2, 4, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Phones ph ON ph.FamilyNumber = p.FamilyNumber AND p.IndividualNumber = ph.IndividualNumber
WHERE ph.Type = 'P' AND ph.Description = 'Mobile' AND ph.Unlisted = 'False';

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, ph.Phone, 2, 6, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Phones ph ON ph.FamilyNumber = p.FamilyNumber AND p.IndividualNumber = ph.IndividualNumber
WHERE ph.Type = 'P' AND ph.Description = 'Mobile' AND ph.Unlisted = 'True';

INSERT INTO civicrm_phone(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT contact_id, phone, phone_type_id, location_type_id, is_primary
FROM ind_phones;

DROP TABLE ind_phones;
/*Process all the Spouses*/
INSERT INTO civicrm_contact (last_name, first_name, middle_name, nick_name, gender_id, birth_date, prefix_id, suffix_id, contact_type, IndividualID, sort_name, display_name)
SELECT p.LastName, p.FirstName, if(p.MiddleName != '', p.MiddleName, NULL), if(p.GoesByName != '', p.GoesByName, NULL), gov.value, if(p.DateofBirth != '', DATE_FORMAT(STR_TO_DATE(p.DateOfBirth, '%m/%d/%Y'), '%Y-%m-%d'), NULL), pov.value, sov.value, 'Individual', p.IndividualID, CONCAT(p.LastName, ', ', p.FirstName), CONCAT(p.Title, ' ', p.FirstName, ' ', p.LastName, ' ', p.Suffix)
FROM acop_data.People p
LEFT JOIN civicrm_option_value gov ON gov.label = p.Gender AND gov.option_group_id = 3
LEFT JOIN civicrm_option_value pov ON pov.label = if(p.Title = 'Miss', 'Miss.', if(p.Title = 'Pastor', 'Pastor.', p.Title)) AND pov.option_group_id = 6
LEFT JOIN civicrm_option_value sov ON sov.label = if(p.Suffix = 'Sr', 'Sr.', if(p.Suffix = 'Jr', 'Jr.', p.Suffix)) AND sov.option_group_id = 7
WHERE IndividualNumber = 11;

INSERT INTO civicrm_relationship (contact_id_a, contact_id_b, is_active, relationship_type_id)
SELECT cc.id, csc.id, 1, 2
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.People pp ON pp.FamilyNumber = p.FamilyNumber
INNER JOIN civicrm_contact csc ON csc.IndividualID = pp.IndividualID
WHERE p.IndividualNumber = 1 AND pp.IndividualNumber = 11;

CREATE TEMPORARY TABLE ind_data
SELECT cc.id as entity_id, if(p.IndDateCredentials != '', p.IndDateCredentials, NULL) as date_credentialed_13, if(p.IndAnniversary != '', p.IndAnniversary, NULL) as anniversary_14, if(p.IndOrdained != '', p.IndOrdained, NULL) as ordained_15, if(p.IndCommenced != '', p.IndCommenced, NULL) as commenced_16, if(p.IndApplicationDate != '', p.IndApplicationDate, NULL) as application_date_17
FROM acop_data.People p
INNER JOIN civicrm_contact cc On cc.IndividualID = p.IndividualID
WHERE p.IndividualNumber = 11;

INSERT INTO civicrm_value_individual_ad_4(entity_id, date_credentialed_13, anniversary_14, ordained_15, commenced_16, application_date_17)
SELECT entity_id, date_credentialed_13, anniversary_14, ordained_15, commenced_16, application_date_17 
FROM ind_data;

DROP TABLE ind_data;

CREATE TEMPORARY TABLE ind_data
SELECT cc.id as entity_id, if(p.IndEducation != '', p.IndEducation, NULL) as education_completed_20, 0 as head_of_family_21, IF(p.IndStatus != '', p.IndStatus, NULL) as status_24, IF(p.IndMarriageRegistration != '', p.IndMarriageRegistration, NULL) as marriage_registration_25
FROM acop_data.People p
INNER JOIN civicrm_contact cc On cc.IndividualID = p.IndividualID
WHERE p.IndividualNumber = 11;

INSERT INTO civicrm_value_individual_ad_6 (entity_id, education_completed_20, head_of_family_21, status_24, marriage_registration_25) 
SELECT entity_id, education_completed_20, head_of_family_21, status_24, marriage_registration_25
FROM ind_data;

DROP TABLE ind_data;

CREATE TEMPORARY TABLE ind_address
SELECT cc.id as contact_id, ca.street_address, ca.supplemental_address_1, ca.state_province_id, ca.country_id, ca.city, ca.id as master_id, ca.location_type_id, ca.is_primary, ca.is_billing
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN civicrm_relationship cr ON cr.contact_id_b = cc.id
INNER JOIN civicrm_address ca ON ca.contact_id = cr.contact_id_a
WHERE p.IndividualNumber = 11;

INSERT INTO civicrm_address (contact_id, street_address, supplemental_address_1, state_province_id, country_id, city, master_id, location_type_id, is_primary, is_billing)
SELECT contact_id, street_address, supplemental_address_1, state_province_id, country_id, city, master_id, location_type_id, is_primary, is_billing
FROM ind_address;

DROP TABLE ind_address;

CREATE TEMPORARY TABLE ind_phones (
 `contact_id` int unsigned DEFAULT NULL,
 `phone` varchar(255),
 `phone_type_id` int unsigned DEFAULT NULL,
 `location_type_id` int unsigned DEFAULT NULL,
 `is_primary` int unsigned DEFAULT 0
);

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, p.PreferredPhone, 1, 3, 1
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
WHERE p.IndividualNumber = 11;

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, p.HomePhone, 1, 3, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
WHERE p.HomePhoneUnlisted = 'FALSE'
AND p.IndividualNumber = 11;

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, p.HomePhone, 1, 6, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
WHERE p.HomePhoneUnlisted = 'TRUE'
AND p.IndividualNumber = 11;

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, ph.Phone, 1, 3, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Phones ph ON ph.FamilyNumber = p.FamilyNumber AND p.IndividualNumber = ph.IndividualNumber
WHERE ph.Type = 'P' AND ph.Description = 'Business' AND ph.Unlisted = 'False' AND p.IndividualNumber = 11;

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, ph.Phone, 1, 6, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Phones ph ON ph.FamilyNumber = p.FamilyNumber AND p.IndividualNumber = ph.IndividualNumber
WHERE ph.Type = 'P' AND ph.Description = 'Business' AND ph.Unlisted = 'True' AND p.IndividualNumber = 11;

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, ph.Phone, 1, 4, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Phones ph ON ph.FamilyNumber = p.FamilyNumber AND p.IndividualNumber = ph.IndividualNumber
WHERE ph.Type = 'P' AND ph.Description = 'Other Home' AND ph.Unlisted = 'FALSE' AND p.IndividualNumber = 11;

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, ph.Phone, 1, 6, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Phones ph ON ph.FamilyNumber = p.FamilyNumber AND p.IndividualNumber = ph.IndividualNumber
WHERE ph.Type = 'P' AND ph.Description = 'Other Home' AND ph.Unlisted = 'True' AND p.IndividualNumber = 11;

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, ph.Phone, 2, 4, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Phones ph ON ph.FamilyNumber = p.FamilyNumber AND p.IndividualNumber = ph.IndividualNumber
WHERE ph.Type = 'P' AND ph.Description = 'Mobile' AND ph.Unlisted = 'False' AND p.IndividualNumber = 11;

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, ph.Phone, 2, 6, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Phones ph ON ph.FamilyNumber = p.FamilyNumber AND p.IndividualNumber = ph.IndividualNumber
WHERE ph.Type = 'P' AND ph.Description = 'Mobile' AND ph.Unlisted = 'True' AND p.IndividualNumber = 11;

INSERT INTO civicrm_phone(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT contact_id, phone, phone_type_id, location_type_id, is_primary
FROM ind_phones;

DROP TABLE ind_phones;

CREATE TEMPORARY TABLE ind_emails
SELECT DISTINCT cc.id as contact_id, e.EmailAddr as email, 3 as location_type_id, 1 as is_primary
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Emails e ON e.FamilyNumber = p.FamilyNumber AND e.IndividualNumber = p.IndividualNumber
WHERE p.IndividualNumber = 11
AND e.Description = 'Spouse - Prefer' OR e.Description = 'Preferred E-mai';

INSERT INTO ind_emails (contact_id, email, location_type_id, is_primary)
SELECT DISTINCT cc.id, e.EmailAddr, 4, 0
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Emails e ON e.FamilyNumber = p.FamilyNumber AND e.IndividualNumber = p.IndividualNumber
WHERE p.IndividualNumber = 11
AND e.Description = 'Other Home' OR e.Description = 'E-mail' OR e.Description = 'Email 2';

INSERT INTO civicrm_email (contact_id, email, location_type_id, is_primary)
SELECT contact_id, email, location_type_id, is_primary
FROM ind_emails;

DROP TABLE ind_emails;
/* Process Children */
INSERT INTO civicrm_contact (last_name, first_name, middle_name, nick_name, gender_id, birth_date, prefix_id, suffix_id, contact_type, IndividualID, sort_name, display_name)
SELECT p.LastName, p.FirstName, if(p.MiddleName != '', p.MiddleName, NULL), if(p.GoesByName != '', p.GoesByName, NULL), gov.value, if(p.DateofBirth != '', DATE_FORMAT(STR_TO_DATE(p.DateOfBirth, '%m/%d/%Y'), '%Y-%m-%d'), NULL), pov.value, sov.value, 'Individual', p.IndividualID, CONCAT(p.LastName, ', ', p.FirstName), CONCAT(p.Title, ' ', p.FirstName, ' ', p.LastName, ' ', p.Suffix)
FROM acop_data.People p
LEFT JOIN civicrm_option_value gov ON gov.label = p.Gender AND gov.option_group_id = 3
LEFT JOIN civicrm_option_value pov ON pov.label = if(p.Title = 'Miss', 'Miss.', if(p.Title = 'Pastor', 'Pastor.', p.Title)) AND pov.option_group_id = 6
LEFT JOIN civicrm_option_value sov ON sov.label = if(p.Suffix = 'Sr', 'Sr.', if(p.Suffix = 'Jr', 'Jr.', p.Suffix)) AND sov.option_group_id = 7
WHERE IndividualNumber = 21;

INSERT INTO civicrm_relationship (contact_id_a, contact_id_b, is_active, relationship_type_id)
SELECT cc.id, csc.id, 1, 1
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.People pp ON pp.FamilyNumber = p.FamilyNumber
INNER JOIN civicrm_contact csc ON csc.IndividualID = pp.IndividualID
WHERE p.IndividualNumber = 21 AND pp.IndividualNumber = 1;

CREATE TEMPORARY TABLE ind_data
SELECT cc.id as entity_id, if(p.IndDateCredentials != '', p.IndDateCredentials, NULL) as date_credentialed_13, if(p.IndAnniversary != '', p.IndAnniversary, NULL) as anniversary_14, if(p.IndOrdained != '', p.IndOrdained, NULL) as ordained_15, if(p.IndCommenced != '', p.IndCommenced, NULL) as commenced_16, if(p.IndApplicationDate != '', p.IndApplicationDate, NULL) as application_date_17
FROM acop_data.People p
INNER JOIN civicrm_contact cc On cc.IndividualID = p.IndividualID
WHERE p.IndividualNumber = 21;

INSERT INTO civicrm_value_individual_ad_4(entity_id, date_credentialed_13, anniversary_14, ordained_15, commenced_16, application_date_17)
SELECT entity_id, date_credentialed_13, anniversary_14, ordained_15, commenced_16, application_date_17 
FROM ind_data;

DROP TABLE ind_data;

CREATE TEMPORARY TABLE ind_data
SELECT cc.id as entity_id, if(p.IndEducation != '', p.IndEducation, NULL) as education_completed_20, 0 as head_of_family_21, IF(p.IndStatus != '', p.IndStatus, NULL) as status_24, IF(p.IndMarriageRegistration != '', p.IndMarriageRegistration, NULL) as marriage_registration_25
FROM acop_data.People p
INNER JOIN civicrm_contact cc On cc.IndividualID = p.IndividualID
WHERE p.IndividualNumber = 21;

INSERT INTO civicrm_value_individual_ad_6 (entity_id, education_completed_20, head_of_family_21, status_24, marriage_registration_25) 
SELECT entity_id, education_completed_20, head_of_family_21, status_24, marriage_registration_25
FROM ind_data;

DROP TABLE ind_data;

CREATE TEMPORARY TABLE ind_address
SELECT cc.id as contact_id, ca.street_address, ca.supplemental_address_1, ca.state_province_id, ca.country_id, ca.city, ca.id as master_id, ca.location_type_id, ca.is_primary, ca.is_billing
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN civicrm_relationship cr ON cr.contact_id_b = cc.id
INNER JOIN civicrm_address ca ON ca.contact_id = cr.contact_id_a
WHERE p.IndividualNumber = 21;

INSERT INTO civicrm_address (contact_id, street_address, supplemental_address_1, state_province_id, country_id, city, master_id, location_type_id, is_primary, is_billing)
SELECT contact_id, street_address, supplemental_address_1, state_province_id, country_id, city, master_id, location_type_id, is_primary, is_billing
FROM ind_address;

DROP TABLE ind_address;

CREATE TEMPORARY TABLE ind_phones (
 `contact_id` int unsigned DEFAULT NULL,
 `phone` varchar(255),
 `phone_type_id` int unsigned DEFAULT NULL,
 `location_type_id` int unsigned DEFAULT NULL,
 `is_primary` int unsigned DEFAULT 0
);

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, p.PreferredPhone, 1, 3, 1
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
WHERE p.IndividualNumber = 21;

INSERT INTO civicrm_phone(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT contact_id, phone, phone_type_id, location_type_id, is_primary
FROM ind_phones;

DROP TABLE ind_phones;

CREATE TEMPORARY TABLE ind_emails
SELECT DISTINCT cc.id as contact_id, e.EmailAddr as email, 3 as location_type_id, 1 as is_primary
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Emails e ON e.FamilyNumber = p.FamilyNumber AND e.IndividualNumber = p.IndividualNumber
WHERE p.IndividualNumber = 21;

DROP TABLE ind_emails;
/*Process other contacts*/
INSERT INTO civicrm_contact (last_name, first_name, middle_name, nick_name, gender_id, birth_date, prefix_id, suffix_id, contact_type, IndividualID, sort_name, display_name)
SELECT p.LastName, p.FirstName, if(p.MiddleName != '', p.MiddleName, NULL), if(p.GoesByName != '', p.GoesByName, NULL), gov.value, if(p.DateofBirth != '', DATE_FORMAT(STR_TO_DATE(p.DateOfBirth, '%m/%d/%Y'), '%Y-%m-%d'), NULL), pov.value, sov.value, 'Individual', p.IndividualID, CONCAT(p.LastName, ', ', p.FirstName), CONCAT(p.Title, ' ', p.FirstName, ' ', p.LastName, ' ', p.Suffix)
FROM acop_data.People p
LEFT JOIN civicrm_option_value gov ON gov.label = p.Gender AND gov.option_group_id = 3
LEFT JOIN civicrm_option_value pov ON pov.label = if(p.Title = 'Miss', 'Miss.', if(p.Title = 'Pastor', 'Pastor.', p.Title)) AND pov.option_group_id = 6
LEFT JOIN civicrm_option_value sov ON sov.label = if(p.Suffix = 'Sr', 'Sr.', if(p.Suffix = 'Jr', 'Jr.', p.Suffix)) AND sov.option_group_id = 7
WHERE IndividualNumber NOT IN (1,21,11);

CREATE TEMPORARY TABLE ind_data
SELECT cc.id as entity_id, if(p.IndDateCredentials != '', p.IndDateCredentials, NULL) as date_credentialed_13, if(p.IndAnniversary != '', p.IndAnniversary, NULL) as anniversary_14, if(p.IndOrdained != '', p.IndOrdained, NULL) as ordained_15, if(p.IndCommenced != '', p.IndCommenced, NULL) as commenced_16, if(p.IndApplicationDate != '', p.IndApplicationDate, NULL) as application_date_17
FROM acop_data.People p
INNER JOIN civicrm_contact cc On cc.IndividualID = p.IndividualID
WHERE p.IndividualNumber NOT IN (1,21,11);

INSERT INTO civicrm_value_individual_ad_4(entity_id, date_credentialed_13, anniversary_14, ordained_15, commenced_16, application_date_17)
SELECT entity_id, date_credentialed_13, anniversary_14, ordained_15, commenced_16, application_date_17 
FROM ind_data;

DROP TABLE ind_data;

CREATE TEMPORARY TABLE ind_data
SELECT cc.id as entity_id, if(p.IndEducation != '', p.IndEducation, NULL) as education_completed_20, 0 as head_of_family_21, IF(p.IndStatus != '', p.IndStatus, NULL) as status_24, IF(p.IndMarriageRegistration != '', p.IndMarriageRegistration, NULL) as marriage_registration_25
FROM acop_data.People p
INNER JOIN civicrm_contact cc On cc.IndividualID = p.IndividualID
WHERE p.IndividualNumber NOT IN (1,21,11);

INSERT INTO civicrm_value_individual_ad_6 (entity_id, education_completed_20, head_of_family_21, status_24, marriage_registration_25) 
SELECT entity_id, education_completed_20, head_of_family_21, status_24, marriage_registration_25
FROM ind_data;

DROP TABLE ind_data;

CREATE TEMPORARY TABLE ind_address
SELECT cc.id as contact_id, p.Address1 as street_address, p.Address2 as supplemental_address_1, p.City as city, sp.id as state_province_id, c.id as country_id, p.ZIPCode as postal_code, 3 as location_type_id, 1 as is_primary, 1 as is_billing
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID 
LEFT JOIN civicrm_country c ON c.name = p.Country
LEFT JOIN civicrm_state_province sp ON sp.abbreviation = p.State AND sp.country_id = c.id
WHERE p.IndividualNumber NOT IN (1,21,11);

INSERT INTO civicrm_address(contact_id, street_address, supplemental_address_1, city, state_province_id, country_id, postal_code, location_type_id, is_primary, is_billing)
SELECT contact_id, street_address, supplemental_address_1, city, state_province_id, country_id, postal_code, location_type_id, is_primary, is_billing
FROM ind_address;

DROP TABLE ind_address;

CREATE TEMPORARY TABLE ind_phones (
 `contact_id` int unsigned DEFAULT NULL,
 `phone` varchar(255),
 `phone_type_id` int unsigned DEFAULT NULL,
 `location_type_id` int unsigned DEFAULT NULL,
 `is_primary` int unsigned DEFAULT 0
);

INSERT INTO ind_phones(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT cc.id, p.PreferredPhone, 1, 3, 1
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
WHERE p.IndividualNumber NOT IN (1,21,11);

INSERT INTO civicrm_phone(contact_id, phone, phone_type_id, location_type_id, is_primary)
SELECT contact_id, phone, phone_type_id, location_type_id, is_primary
FROM ind_phones;

DROP TABLE ind_phones;

CREATE TEMPORARY TABLE ind_emails
SELECT DISTINCT cc.id as contact_id, e.EmailAddr as email, 3 as location_type_id, 1 as is_primary
FROM acop_data.People p
INNER JOIN civicrm_contact cc ON cc.IndividualID = p.IndividualID
INNER JOIN acop_data.Emails e ON e.FamilyNumber = p.FamilyNumber AND e.IndividualNumber = p.IndividualNumber
WHERE e.Description = 'Preferred E-mai' AND p.IndividualNumber NOT IN (1,21,11);

INSERT INTO civicrm_email (contact_id, email, location_type_id, is_primary)
SELECT contact_id, email, location_type_id, is_primary
FROM ind_emails;

DROP TABLE ind_emails;

CREATE TEMPORARY TABLE orgStaffDetails
SELECT cc.id as entity_id, church.id as current_acop_church_1, group_concat(os.Position) as current_ministry_title_3
FROM civicrm_contact cc
INNER JOIN acop_org_data.OrgStaff os ON os.IndividualID = cc.IndividualID
INNER JOIN acop_org_data.Orgs as o ON o.OrgId = os.OrgID
INNER JOIN civicrm_contact church ON church.OrgID = o.OrgID
GROUP BY os.IndividualID
HAVING COUNT(DISTINCT o.OrgID) = 1;

/*INSERT INTO orgStaffDetails(entity_id, current_acop_church_1, current_ministry_title_3)
SELECT cc.id as entity_id, 0 as current_acop_church_1, group_concat(os.Position) as current_ministry_title_3
FROM civicrm_contact cc
INNER JOIN acop_org_data.OrgStaff os ON os.IndividualID = cc.IndividualID
INNER JOIN acop_org_data.Orgs as o ON o.OrgId = os.OrgID
INNER JOIN civicrm_contact church ON church.OrgID = o.OrgID
GROUP BY os.IndividualID
HAVING COUNT(DISTINCT o.OrgID) > 1;*/

INSERT INTO civicrm_value_church_minist_1 (entity_id, current_acop_church_1, current_ministry_title_3)
SELECT entity_id, current_acop_church_1, current_ministry_title_3
FROM orgStaffDetails;

DROP TABLE orgStaffDetails;

INSERT INTO civicrm_relationship (contact_id_a, contact_id_b, is_active, relationship_type_id)
SELECT cc.id as contact_id_a, church.id as contact_id_b, 1, 11
FROM civicrm_contact cc
INNER JOIN acop_org_data.OrgStaff os ON os.IndividualID = cc.IndividualID
INNER JOIN acop_org_data.Orgs as o ON o.OrgId = os.OrgID AND o.ContactIndLabel = os.IndLabel
INNER JOIN civicrm_contact church ON church.OrgID = o.OrgID
WHERE o.ContactIndLabel != ''
GROUP BY o.OrgID, os.IndividualID;
