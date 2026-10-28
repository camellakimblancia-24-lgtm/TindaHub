# TindaHub

TindaHub is a mobile app for sari-sari store owners to keep product stock, daily
sales, and customer utang in one place.

## Current MVP

- Dashboard with daily sales, total utang, and low-stock alerts
- Product list with search, add, edit, and delete
- Sale recording for paid purchases or customer credit
- Automatic stock deductions when a sale is saved
- Customer utang balances with payment recording and account activity
- Customer search and 30-day overdue utang reminders
- Daily, weekly, and monthly sales summaries with a seven-day trend chart
- Best-selling product counts based on recorded sale quantities
- Editable store owner display name from the profile button; no account or
  password is required
- Open Food Facts barcode lookup when adding or editing a product, including
  available product name, brand, package size, and product image
- Manual product entry remains available when a barcode is not found or the
  API cannot be reached

The current version uses sample data stored in memory. Changes, including the
owner display name, are lost when the app restarts. Product lookup uses the
public Open Food Facts API and sends the required `TindaHub/1.0` User-Agent; it
does not require an API key.

## Project member

- Camella Kim B. Blancia

## Run locally

From the `tindahub` project directory:

```sh
flutter pub get
flutter run
```
