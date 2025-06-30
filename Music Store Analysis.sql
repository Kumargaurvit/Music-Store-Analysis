Use music_store;

-- 1. Who is the senior most employee based on job title? 
Select first_name, last_name, title from employee
Where levels in (select max(levels) from employee);

-- 2. Which countries have the most Invoices? 
Select count(*) as [No. of Invoices], billing_country from invoice
group by billing_country order by [No. of Invoices] desc;

-- 3. What are top 3 values of total invoice? 
Select top 3 total from invoice
order by total desc;

/* 4. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */
Select billing_city, SUM(total) as [Invoice Totals] from invoice
Group by billing_city
order by [Invoice Totals] desc;

/* 5. Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money */
Select top 1 c.first_name, c.last_name, SUM(i.total) as [Total Spent]  from customer c
JOIN invoice i
ON c.customer_id = i.customer_id
Group by first_name, last_name
Order by [total spent] desc;

/* 6. Write query to return the email, first name, last name, & Genre of all Rock Music 
listeners. Return your list ordered alphabetically by email starting with A */
Select c.first_name, c.last_name, c.email from customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
Where il.track_id IN (
	Select track_id from track t
	JOIN genre g ON t.genre_id = g.genre_id
	WHERE g.name LIKE 'Rock')
group by c.first_name, c.last_name, c.email
Order by c.email;

/* 7. Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands */
Select Top 10 a.name as [Artist Name], COUNT(*) as [Track Count] from artist a
JOIN album al ON a.artist_id = al.artist_id
JOIN track t ON al.album_id = t.album_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name LIKE 'Rock'
Group by a.name
Order by [Track Count] desc;

/* 8. Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. 
Order by the song length with the longest songs listed first */
Select t.name as [Song Name], t.milliseconds from track t
Where t.milliseconds > (
	Select AVG(milliseconds) from track
)
ORDER by t.milliseconds DESC;

/* 9. Find how much amount spent by each customer on artists? 
Write a query to return customer name, artist name and total spent */
With Best_selling_artist as (
	Select TOP 1 a.artist_id as artist_id, a.name as artist_name, SUM(il.unit_price * il.quantity) as [Total Sales] 
	From invoice_line il
	JOIN track t ON il.track_id = t.track_id
	JOIN album al ON t.album_id = al.album_id
	JOIN artist a ON al.artist_id = a.artist_id
	GROUP BY a.name, a.artist_id
	ORDER BY [Total Sales] DESC
)
Select c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price * il.quantity) as [Total Spent] from invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album al ON al.album_id = t.album_id
JOIN Best_selling_artist bsa ON bsa.artist_id = al.artist_id
GROUP BY c.first_name, c.last_name, bsa.artist_name
ORDER BY [Total Spent] desc;

/* 10. We want to find out the most popular music Genre for each country. 
We determine the most popular genre as the genre with the highest amount of purchases.
Write a query that returns each country along with the top Genre. 
For countries where the maximum number of purchases is shared return all Genres */
WITH popular_genre AS (
    SELECT 
        COUNT(il.quantity) AS purchases, c.country, 
        g.name AS genre_name, g.genre_id,
        ROW_NUMBER() OVER (
		PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC
        ) AS RowNo
    FROM invoice_line il
    JOIN invoice i ON i.invoice_id = il.invoice_id
    JOIN customer c ON c.customer_id = i.customer_id
    JOIN track t ON t.track_id = il.track_id
    JOIN genre g ON g.genre_id = t.genre_id
    GROUP BY c.country, g.name, g.genre_id
)
SELECT * FROM popular_genre WHERE RowNo = 1;

/* 11. Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount */
With Top_spending_customer as (
	Select c.first_name, c.last_name, c.country, SUM(il.unit_price * il.quantity) as [Total Spent],
	ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY SUM(il.unit_price * il.quantity) DESC) as RowNo
	From invoice_line il
	JOIN invoice i ON i.invoice_id = il.invoice_id
	JOIN customer c ON c.customer_id = i.customer_id
	GROUP BY c.first_name, c.last_name, c.country
)
Select * from Top_spending_customer where RowNo = 1
Order By Top_spending_customer.country, Top_spending_customer.[Total Spent] desc;

/* 12. Calculate the total sales for each Sales Support Agent. 
Rank them by their total sales. 
Include the employee's first_name, last_name, and their total sales. */
With employee_sales as (
	Select e.first_name, e.last_name, SUM(il.unit_price * il.quantity) as [Total Sales] 
	From employee e
	JOIN customer c ON c.support_rep_id = e.employee_id
	JOIN invoice i ON i.customer_id = c.customer_id
	JOIN invoice_line il ON il.invoice_id = i.invoice_id
	Where e.title LIKE 'Sales Support Agent'
	Group by e.first_name, e.last_name
)
Select first_name, last_name, [Total Sales],
RANK() OVER(ORDER BY [Total Sales] desc) as Sales_rank
from employee_sales
Order by Sales_rank;

-- 13. Find the top 5 artists by total sales. Display the artist_name and their total sales.
Select Top 5 a.name, SUM(il.unit_price * il.quantity) as [Total Sales] 
From invoice_line il
JOIN track t ON t.track_id = il.track_id
JOIN album al ON al.album_id = t.album_id
JOIN artist a ON a.artist_id = al.artist_id
Group by a.name
Order by [Total Sales] desc;

/* 14. Identify customers who have made more than one purchase (i.e., have more than one invoice) within the same month and year. 
Display customer_id, first_name, last_name, the year of the invoice, the month of the invoice
and the count of invoices for that customer in that specific month and year. */
Select i.customer_id, c.first_name, c.last_name, YEAR(i.invoice_date) as [Year of invoice], 
MONTH(i.invoice_date) as [Month of invoice], COUNT(*) as [No. of Invoices]
From invoice i
JOIN customer c ON c.customer_id = i.customer_id
Group By i.customer_id, c.first_name, c.last_name, YEAR(i.invoice_date), MONTH(i.invoice_date)
HAVING COUNT(*) > 1;

/* 15. Calculate the month-over-month growth rate in total sales for the entire dataset. 
Display the year, month, total_monthly_sales, previous_month_sales, and monthly_growth_rate_percentage. */
With monthly_sales as (
	Select YEAR(i.invoice_date) as sale_year, MONTH(i.invoice_date) as sale_month,
	SUM(total) as total_sales
	from invoice i
	Group by YEAR(i.invoice_date), MONTH(i.invoice_date)
),
Lagged_monthly_sales as (
Select sale_year, sale_month, total_sales,
LAG(total_sales,1,0) OVER(ORDER BY sale_year, sale_month) as previous_month_sales
from monthly_sales
)
SELECT sale_year, sale_month, total_sales, previous_month_sales,
CASE 
	WHEN previous_month_sales = 0 THEN NULL
	ELSE ((total_sales - previous_month_sales) / previous_month_sales) * 100
END AS monthly_sale_grow_rate
from Lagged_monthly_sales
group by sale_year, sale_month, total_sales, previous_month_sales;