# ## Setting Up Environment

# 1. Go to https://customvision.ai/  and sign in with your azure account/ID
# 2. Once you are in, go to Settings (gear icon - upper right corner) and copy your Limited Trial Prediction and Training Key

# In[1]:

import sys


# In[2]:


#This is only one time run to install the required python libraries on this virtual machine
get_ipython().system(u'{sys.executable} -m pip install -U azure-cognitiveservices-vision-customvision')


# ## Initialize the libraries and origin and destination workspaces

# In[4]:


from azure.cognitiveservices.vision.customvision.training import CustomVisionTrainingClient
from azure.cognitiveservices.vision.customvision.training.models import ImageUrlCreateEntry

ENDPOINT = "<enter endpoint url - for example: https://southcentralus.api.cognitive.microsoft.com>"

# DESTINATION Resource Group Keys **************************************************
dest_training_key = "<enter destination training key>"

dest_project_new_name = "My Project 123 - Copy"

# 1. Go to https://customvision.ai/  and sign in with your azure account/ID
# 2. Once you are in, go to Settings (gear icon - upper right corner) and copy the prediction_resource_id
prediction_resource_id ='/subscriptions/<>/resourceGroups/<enter your rg name>/providers/Microsoft.CognitiveServices/accounts/<enter your rg name>_prediction'

# ORIGIN Resource Group Keys **************************************************
training_key = "<enter source training key>"

project_id="<enter source project id>" 

trainer = CustomVisionTrainingClient(training_key, endpoint=ENDPOINT)

dest_trainer = CustomVisionTrainingClient(dest_training_key, endpoint=ENDPOINT)

# Find the image classification domain
classification_domain = next(domain for domain in trainer.get_domains() if domain.type == "Classification")
dest_classification_domain = next(domain for domain in dest_trainer.get_domains() if domain.type == "Classification")


# ## Get the origin project ID reference

# In[5]:


myProjects = trainer.get_projects()


# In[6]:


for project in myProjects:
    print(project.name)
    print(project.id)
    print(project.description)


# In[7]:


Project = trainer.get_project(project_id=project_id)


# ## Create the destination Project 

# In[8]:


dest_Project = dest_trainer.create_project(dest_project_new_name, domain_id=dest_classification_domain.id)


# In[9]:


for project in dest_trainer.get_projects():
    print(project.name)
    print(project.id)
    print(project.description)


# ## Get the tags on origin project and create same tags on destination project

# In[10]:


dest_tags = []
for tag in trainer.get_tags(Project.id):
    dest_tags.append(dest_trainer.create_tag(dest_Project.id, tag.name))
    print(tag.name)


# In[11]:


dest_tags_dict = {}
dest_tag_ids = []
for tag in dest_tags:
    dest_tags_dict[tag.name] = tag.id
    dest_tag_ids.append(tag.id)

print(dest_tags_dict)
print(dest_tag_ids)


# ## Get the images on origin project

# In[48]:


import math
tagged_image_count=0
tagged_image_count=trainer.get_tagged_image_count(Project.id)

batchStartIndex=0
batchMaxIndex=256
num_batches=math.ceil(tagged_image_count/256)

print(tagged_image_count)
print(batchStartIndex)
print(batchMaxIndex)
print(num_batches)

tagged_images = []
for  index in range(batchStartIndex, num_batches):
    print(batchStartIndex, batchMaxIndex)
    tagged_images.extend( trainer.get_tagged_images(Project.id, skip=batchStartIndex, take=256) )
    batchStartIndex+=256
    batchMaxIndex+=256
    if(batchMaxIndex > tagged_image_count):
        batchMaxIndex = tagged_image_count



# In[50]:


tagged_images_with_tags = []
for image in tagged_images: #for each tagged image on origin
    dest_tags_ids = []
    
    for tag in image.tags: #for each tag on the origin image
        dest_tags_ids.append(dest_tags_dict[tag.tag_name]) #append it to the image dest_tags_ids list
    #print(image)
    tagged_images_with_tags.append(ImageUrlCreateEntry(url=image.original_image_uri, tag_ids=dest_tags_ids))
    #tagged_images_with_tags.append(ImageUrlCreateEntry(url=image.image_uri, tag_ids=dest_tags_ids))
print("Done")


# ## Create the images with regions on destination project

# In[52]:


print(len(tagged_images))
print(len(tagged_images_with_tags))

print(len(dest_tags_ids))


# In[53]:


limit = 64 # this is a limit imposed on the API, so we need to batch the creation process
count_of_images = len(tagged_images_with_tags)

for i in range(0,count_of_images,limit):
    begin=i
    end=limit+i
    if(end > count_of_images ): end = count_of_images
    dest_trainer.create_images_from_urls(dest_Project.id, images=tagged_images_with_tags[begin:end])


# In[57]:


print("Count of Tagged images on origin project: " + str(trainer.get_tagged_image_count(Project.id)))
print("Count of Tagged images on destination project: " + str(dest_trainer.get_tagged_image_count(dest_Project.id)))
print(prediction_resource_id)