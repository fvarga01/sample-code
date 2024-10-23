#create initial sample csv data, represents non-anonymized data

#anonymize data
import pandas as pd
from faker import Faker
fake = Faker()

data = {'id': [1, 2, 3, 4, 5],
        'company_address': ['123 Main St.', '345 Maple Ave.', '678 Elm St.', '901 Oak Ave.', '234 Pine St.'],
        'sales_currency': ['USD', 'EUR', 'JPY', 'GBP', 'AUD'],
        'sales_last_quarter': ['1000.11', '2000.22', '3000.33', '4000.44', '5000.55'],
        'company_name': ['Cisco', 'Google', 'Apple', 'Microsoft', 'Amazon'],
        'company_contact': ['John Doe', 'Jane Doe', 'Jack Smith', 'Jill Smith', 'Jim Brown']
        }
df = pd.DataFrame(data)
df.to_csv('data.csv', index=False)

#load data
data = pd.read_csv('data.csv')
print(data) #before anonymization

#anonymize data
data['company_address'] = data['company_address'].apply(lambda x: fake.address())
data['sales_currency'] = data['sales_currency'].apply(lambda x: fake.currency_code())
data['sales_last_quarter'] = data['sales_last_quarter'].apply(lambda x: str(fake.random_int(1000, 10000)) + '.' + str(fake.random_int(10, 99)))
data['company_name'] = data['company_name'].apply(lambda x: fake.company())
data['company_contact'] = data['company_contact'].apply(lambda x: fake.name())
#export to csv
data.to_csv('anonymized_data.csv', index=False)

print(data) #after anonymization
