from random import randint 
from faker import Faker
import pandas as pd 
fake = Faker()
def input_data(x):
    # pandas dataframe
    data = pd.DataFrame()
    for i in range(0, x):
        data.loc[i,'id']= randint(1, 100)
        data.loc[i,'company_address']= fake.address()
        data.loc[i,'sales_currency']=fake.currency_code()
        data.loc[i,'sales_last_quarter']=  str(randint(1000, 10000)) + '.' + str(randint(10, 99))
        #company name
        data.loc[i,'company_name']= fake.company()
        #company contact
        data.loc[i,'company_contact']= fake.name()
        data.loc[i,'company_contact_email']= str(fake.company_email())
    return data
   
print( input_data(10))
#export to csv
input_data(10).to_csv('data.csv', index=False)
