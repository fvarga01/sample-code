#%% Change working directory from the workspace root to the ipynb file location. Turn this addition off with the DataScience.changeDirOnImportExport setting
import os
try:
	os.chdir(os.path.join(os.getcwd(), 'Python'))
	print(os.getcwd())
except:
	pass
#%% [markdown]
# # How to copy to/from the same blob container

#%%
#https://github.com/Azure/azure-storage-python/blob/master/samples/blob/block_blob_usage.py
#https://stackoverflow.com/questions/32500935/python-how-to-move-or-copy-azure-blob-from-one-container-to-another
#https://docs.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-python
#https://docs.microsoft.com/en-us/python/api/azure-storage-blob/azure.storage.blob.blockblobservice.BlockBlobService?view=azure-python#copy-blob-container-name--blob-name--copy-source--metadata-none--source-if-modified-since-none--source-if-unmodified-since-none--source-if-match-none--source-if-none-match-none--destination-if-modified-since-none--destination-if-unmodified-since-none--destination-if-match-none--destination-if-none-match-none--destination-lease-id-none--source-lease-id-none--timeout-none--requires-sync-none-
#REST https://docs.microsoft.com/en-us/rest/api/storageservices/service-sas-examples
#https://azure-storage.readthedocs.io/ref/azure.storage.blob.blockblobservice.html
#https://stackoverflow.com/questions/25038429/azure-shared-access-signature-signature-did-not-match
#https://social.msdn.microsoft.com/Forums/sharepoint/en-US/7c4b8021-c65d-45e5-8442-1dc8c844a761/how-to-create-shared-access-signature-of-blob-in-azure-blob-storage-using-rest-api-c?forum=windowsazuredata

!pip install azure-storage-blob
!pip install azure-storage-common

#%%
from datetime import datetime, timedelta
from azure.storage.blob import BlockBlobService,BlobPermissions

account_key = '<>'
account_name='<>'
blob_name = 'test1.txt'
container_name= 'container1'
copy_from = 'container1/f1'
copy_to= 'container1/f2'
blob_name='test1.txt'

blob_service = BlockBlobService(account_name=account_name, account_key=account_key)

#Create a client side SAS token
sas_token1 = blob_service.generate_container_shared_access_signature(container_name,BlobPermissions.WRITE |BlobPermissions.READ , datetime.utcnow() + timedelta(hours=4))

#Create a SAS block service
blob_service2 = BlockBlobService(account_name=account_name, sas_token=sas_token1)

#Create a sas url
blob_url = blob_service2.make_blob_url(copy_from,blob_name, sas_token=sas_token1)

#copy from blob_url to the copy_to location 
blob_service2.copy_blob(copy_to,blob_name=blob_name, copy_source=blob_url)

print('Debug: Showing contents of source file')
print( blob_service2.get_blob_to_text(copy_from, blob_name).content )
print('Debug: Showing contents of destination (copied) file')
print( blob_service2.get_blob_to_text(copy_to, blob_name).content ) #should exist now



#%%



#%%


#%%


