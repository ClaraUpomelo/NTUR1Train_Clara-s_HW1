#HW1
#Set & Read data
setwd("D:/HW1forR")
sessions <- read.table('sessions.csv', sep=',', stringsAsFactors=T, header=T,nrows = 200)
TrainUsers <- read.table('train_users_2.csv', sep=',', stringsAsFactors=T, header=T,nrows = 200)
TestUsers <- read.table('test_users.csv', sep=',', stringsAsFactors=T, header=T,nrows = 200)
#install packages
install.packages("ggplot2")
install.packages("sqldf")
install.packages("reshape2")
install.packages("magrittr")
#libraries
library(ggplot2)
library(sqldf)
library(reshape2)
#資料整理，將同類型的動作合併同一欄位
sessions$action_type[sessions$action_type==''] <- '-unknown-'
sessionsActionType <- sqldf("select user_id, 
                 case when action_type=='booking_request' then 'booking_request'
                 when action_type=='booking_response' then 'booking_response'
                 when action_type=='click' then 'click'
                 when action_type=='data' then 'data'
                 when action_type=='message_post' then 'message_post'
                 when action_type=='modify' then 'modify'
                 when action_type=='partner_callback' then 'partner_callback'
                 when action_type=='submit' then 'submit'
                 when action_type=='view' then 'view'
                 else 'other_action_types' end as action_type,
                 sum(secs_elapsed) as secs_elapsed
                 from sessions
                 group by user_id, action_type")
#28行將所有未歸類的歸類至other_action_types，29行將other_action_types合算
sessionsDeviceType <- sqldf("select user_id,
                            case when device_type=='Android App Unknown Phone/Tablet' then 'android_app_unknown_phone_tablet'
                            when device_type=='Android Phone' then 'android_phone'
                            when device_type=='Blackberry' then 'blackberry'
                            when device_type=='Chromebook' then 'chromebook'
                            when device_type=='iPad Tablet' then 'iPad_tablet'
                            when device_type=='iPodtouch' then 'iPodtouch'
                            when device_type=='Linux Desktop' then 'linux_desktop'
                            when device_type=='Mac Desktop' then 'mac_desktop'
                            when device_type=='Opera Phone' then 'opera_phone'
                            when device_type=='Tablet' then 'tablet'
                            when device_type=='Windows Desktop' then 'windows_desktop'
                            when device_type=='Windows Phone' then 'windows_phone'
                            else 'other_device_types' end as device_type,
                            sum(secs_elapsed) as secs_elapsed
                            from sessions
                            group by user_id, device_type")
sessionsActionTypeNew <- subset(sessionsActionType, user_id!='')
sessionsDeviceTypeNew <- subset(sessionsDeviceType, user_id!='')
row.names(sessionsActionTypeNew) <- NULL
row.names(sessionsDeviceTypeNew) <- NULL
#dcast計算數量
userActionType <- dcast(sessionsActionTypeNew, user_id~action_type, sum)
userDeviceType <- dcast(sessionsDeviceTypeNew, user_id~device_type, sum)
#merge兩個欄位
userActionDeviceSecsElapsed <- merge(userActionType, userDeviceType, by="user_id", all.x=T, all.y=T)
#NA以0取代
userActionDeviceSecsElapsed[is.na(userActionDeviceSecsElapsed)] <- 0
#合併TranUsers與sessions
names(TrainUsers)[1] <- "user_id"
train <- merge(TrainUsers, userActionDeviceSecsElapsed, by="user_id", all.x=TRUE)
