*Importing all datasets in SAS data environment; 
FILENAME REFFILE '/folders/myfolders/Graded Project/Data1.csv';
PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.agent_score;
	GETNAMES=YES;
RUN;

FILENAME REFFILE '/folders/myfolders/Graded Project/Data2.csv';
PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.online;
	GETNAMES=YES;
RUN;

FILENAME REFFILE '/folders/myfolders/Graded Project/Data3.csv';
PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.roll_agent;
	GETNAMES=YES;
RUN;

FILENAME REFFILE '/folders/myfolders/Graded Project/Data4.csv';
PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.third_party;
	GETNAMES=YES;
RUN;


*Data cleaning;

*Creating one dataset from all datasets;
data appended;
set online roll_agent third_party;
run;

proc sql;
create table proj as
select * from appended left join agent_score
on appended.agentid = agent_score.AgentID;
quit;


*Removing unwanted variables;
data proj;
set proj(drop= hhid custid proposal_num);
run;


*Performing basic EDA;
*1. Find out the annual premium for all customers?;
data premium;
set proj;
AnnualPremium =0;
run;

proc sql;
	update premium set AnnualPremium = (case 
		when payment_mode = 'Annual' then Premium*1
		when payment_mode = 'Semi Annual' then Premium*2
		when payment_mode = 'Quaterly' then Premium*4
		else Premium*12 
	end);
quit;

*2. Calculate age and tenure as of 31 Jan 2020 for all customers?;
data age;
set premium;
Age = intck('year',dob,'31jan2020'd);
Tenure = intck('month',policy_date,'31jan2020'd);
run;

*3. Creating a product name by using both level of product information. ;
data final;
set age;
Product_name = substr(product_lvl2,6); *Removing code from product name;
run;

data final;
set final;
Final_Product_Name = trim(product_lvl1)|| ' ' || Product_name; *Making it more representable;
run;

*4. Calculating the distribution of customers across product and policy status?;
proc sql;
	create table total_dist as
	select policy_status, Final_Product_Name , count(*) as distribution_count from final
	group by policy_status, Final_Product_Name
	order by distribution_count;
quit;

*Categorical Analysis of the data for better insights;
	
	*1. According to Policy Status;
	proc sql;
		create table dist_by_status as
		select policy_status,  count(*) as distribution_count from final
		group by policy_status
		order by distribution_count;
	quit;
	
	*2. According to type of product;
	proc sql;
		create table dist_by_product as
		select  Final_Product_Name , count(*) as distribution_count from final
		group by  Final_Product_Name
		order by distribution_count;
	quit;

*5. Calculating Average annual premium for different payment mode?;
proc sql;
	create table avg_premium as
	select payment_mode , avg(AnnualPremium) as Avg_Premium from final
	group by payment_mode
	order by Avg_Premium;
quit;

*6. Calculating Average persistency score, no fraud score and tenure of customers across product and policy status?;
proc sql;
	create table avg_data as
	select Final_Product_name as Product, 
	policy_status as Status, 
	avg(Persistency_Score) as Avg_Persistency_Score,
	avg(NoFraud_Score) as Avg_No_fraud_Score, 
	avg(Tenure)  as Avg_Tenure
	from final
	group by Final_Product_name, policy_status;
	/*order by Avg_No_fraud_Score;*/
	/*order by Avg_Tenure;*/
	/*order by Avg_Persistency_Score;*/
quit;

proc print data=avg_data;
run;


*7. Calculating Average age of customer across acquisition channel and policy status?; 
proc sql;
	create table avg_age_analysis as
	select acq_chnl as Acquisition_Channel, policy_status ,avg(Age) as Customer_Age
	from final
	group by Acquisition_Channel, policy_status
	order by Customer_Age;
quit;