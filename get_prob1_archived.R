
pXTX<-function(path1,target_country,years,ages,t_cycle,cycle,PFS,OS){
#创建一个数据框，保存转移概率
df <- data.frame("pFTF" = as.numeric(0),
                  "pFTD" = as.numeric(0),
                  "pFTP" = as.numeric(0),
                  "pPTP" = as.numeric(0),
                  "pPTD" = as.numeric(0),
                  "pSTS" = as.numeric(0),
                  "nSUR" = as.numeric(0),
                  "nPFS" = as.numeric(0),
                  "nPD" = as.numeric(0))

path2 <- paste(path1,"CountryList.csv",sep="\\")
CountryList <- read.csv(path2, header = TRUE)
#选择所需死亡率的目标国家
#target_country <- "USA"
# 查找行和列索引
row_index <- which(CountryList$Country == target_country)
a <- CountryList[row_index,1]
a1 <- paste(a, n1, sep = ".")
path3 <- paste(path1,n2,a1,sep="\\")
df1 <- read.table(path3, header = TRUE, skip = 2)

a3 <- df1[df1$Year == years & df1$Age %in% c(ages:(t_cycle+ages-1)), ]

for(i in 1:t_cycle){
  a4 <-1-exp(-(-(log(1-a3[i,"qx"]))/1)*a_cycle/365.24)
  for (j in seq_len(as.integer(365.24/a_cycle))) {
    df[(as.integer(365.24/a_cycle))*(i-1)+j,"pFTD"] <- a4
  }
}

df[,"pFTD"] <- as.numeric(df[,"pFTD"])
#计算PFS to Death 转移概率

for(i in 2:cycle){
  df[i,"pFTF"] <- PFS[i,md_pfs]/PFS[i-1,md_pfs]
}
df[is.na(df[,"pFTF"]), "pFTF"] <- 0
df[1,"pFTF"] <- PFS[1,md_pfs]
df[,"pFTF"] <- as.numeric(df[,"pFTF"])
#计算PFS to PFS 转移概率
df$pFTD[is.na(df$pFTD)] <- max(df$pFTD[!is.na(df$pFTD)])
#填充PFS to Death 的NA



for(i in 1:cycle){
  df[i,"pFTP"] <- 1-df[i,"pFTF"]-df[i,"pFTD"]
}

a5 <- which(df$pFTP < 0)
for(i in a5 ){
  df[i,"pFTP"] <- as.numeric(0)
  df[i,"pFTF"] <- as.numeric(1-df[i,"pFTD"])
}
##调整异常值  

for(i in 2:cycle){
  df[i,"pSTS"] <- OS[i,md_os]/OS[i-1,md_os]
}
df[1,"pSTS"] <- OS[1,md_os]
df[,"pSTS"] <- as.numeric(df[,"pSTS"])
df[is.na(df[,"pSTS"]), "pSTS"] <- 0
#计算OS to OS 转移概率
#---------------------------

df[,"nSUR"] <- 1
for(i in 2:cycle){
  df[1,"nSUR"] <- 1000-1000*df[1,"pFTD"]
  df[i,"nSUR"] <- df[i-1,"nSUR"]*df[i,"pSTS"]
}
#计算OS人数

df[,"nPFS"] <- 1
for(i in 2:cycle){
  df[1,"nPFS"] <- 1000*df[1,"pFTF"]
  df[i,"nPFS"] <- df[i-1,"nPFS"]*df[i,"pFTF"]
}
#计算PFS人数

df[,"nPD"] <- as.numeric(1)
df[,"pPTD"] <-as.numeric(0)
df[,"pPTP"] <-as.numeric(0)

for(i in 2:cycle){
  df[1,"nPD"] <- as.numeric(df[1,"nSUR"]) - as.numeric(df[1,"nPFS"])
  df[i,"pPTD"] <- (as.numeric(df[i-1,"nSUR"]) - as.numeric(df[i,"nSUR"])
                   - as.numeric(df[i-1,"nPFS"]) * df[i-1,"pFTD"]) / df[i-1,"nPD"]
  if(is.infinite(df[i, "pPTD"]) || df[i, "pPTD"] < 0){
    df[i,"pPTD"] <- 0
  }
  if(df[i,"pPTD"] > 1){
    df[i,"pPTD"] <- 1
  }
  df[i,"pPTP"] <- 1 - df[i,"pPTD"]
  df[i,"nPD"] <- (df[i-1,"nPFS"]) * df[i,"pFTP"] + (df[i-1,"nPD"]) * df[i,"pPTP"]
}

return(df)
}

