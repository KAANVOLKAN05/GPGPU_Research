import pandas as pd
import matplotlib.pyplot as plt
df = pd.read_csv('gpu_stats.csv',header = None)


print(df.head())



GPU1 = df[df.iloc[:,1] == 1]
GPU2 = df[df.iloc[:,1] == 2]
GPU3 = df[df.iloc[:,1] == 3]
GPU4 = df[df.iloc[:,1] == 4]
GPU5 = df[df.iloc[:,1] == 5]
GPU6 = df[df.iloc[:,1] == 6]
GPU7 = df[df.iloc[:,1] == 7]

print(GPU1)
GPU1.plot.scatter(x=0, y=1)
plt.savefig("GPUAnalysis1.pdf", format="pdf")
