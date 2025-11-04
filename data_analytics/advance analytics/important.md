# 📈 SQL Analytical Techniques

This document highlights key analytical approaches used in SQL for business intelligence, trend monitoring, and performance evaluation.

---

## 🔄 Change Over Time Analysis
---

### 🎯 **Purpose**
- Track **trends, growth, and changes** in key metrics over time.  
- Perform **time-series analysis** to identify **seasonality** or recurring patterns.  
- Measure **growth or decline** across specific time periods.

### 🧠 **SQL Functions Used**
- **Date Functions:** `DATEPART()`, `DATETRUNC()`, `FORMAT()`  
- **Aggregate Functions:** `SUM()`, `COUNT()`, `AVG()`

---

## 📊 Cumulative Analysis
---

### 🎯 **Purpose**
- Calculate **running totals** or **moving averages** for performance tracking.  
- Monitor **progress and growth trends** over time.  
- Useful for **cumulative growth analysis** or long-term performance evaluation.

### 🧠 **SQL Functions Used**
- **Window Functions:** `SUM() OVER()`, `AVG() OVER()`

---

## 📆 Performance Analysis  
*(Year-over-Year, Month-over-Month)*
---

### 🎯 **Purpose**
- Measure **product, customer, or regional performance** across different time frames.  
- Enable **benchmarking** to identify **high-performing entities**.  
- Track **yearly or monthly growth trends** for business insights.

### 🧠 **SQL Functions Used**
- `LAG()` → Access data from previous rows for comparison.  
- `AVG() OVER()` → Compute rolling or partitioned averages.  
- `CASE` → Define **conditional logic** for **trend classification**.

---

## 🧩 Data Segmentation Analysis
---

### 🎯 **Purpose**
- Group data into **meaningful segments** for targeted insights.  
- Support **customer segmentation**, **product categorization**, or **regional analysis**.  
- Simplify analysis by categorizing data into business-relevant groups.

### 🧠 **SQL Functions Used**
- `CASE` → Define **custom segmentation rules**.  
- `GROUP BY` → Create **aggregated summaries** per segment.

---

## ⚖️ Part-to-Whole Analysis
---

### 🎯 **Purpose**
- Compare **performance metrics** across categories or time periods.  
- Evaluate **proportions and contributions** to overall totals.  
- Ideal for **A/B testing**, **market share analysis**, or **regional comparisons**.

### 🧠 **SQL Functions Used**
- **Aggregate Functions:** `SUM()`, `AVG()`  
- **Window Functions:** `SUM() OVER()` → Calculate total for percentage contribution.

---

📌 *These analytical methods form the backbone of SQL-based business intelligence and help translate raw data into strategic insights.*
