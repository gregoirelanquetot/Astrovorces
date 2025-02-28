from flask import Flask, request, render_template
import pandas as pd
import numpy as np

app = Flask(__name__)

divorce_data = pd.read_csv("divorces_2000-2015_translated.csv").dropna()
astro_data = pd.read_csv("Comp_matrix.csv").dropna()

# Function to calculate zodiac sign
def zodiac_sign(day, month):
    zodiac_dates = [(20, "Capricorn", "Aquarius"), (19, "Aquarius", "Pisces"), (21, "Pisces", "Aries"),
                    (20, "Aries", "Taurus"), (21, "Taurus", "Gemini"), (21, "Gemini", "Cancer"),
                    (23, "Cancer", "Leo"), (23, "Leo", "Virgo"), (23, "Virgo", "Libra"),
                    (23, "Libra", "Scorpio"), (22, "Scorpio", "Sagittarius"), (22, "Sagittarius", "Capricorn")]
    return zodiac_dates[month - 1][1] if day < zodiac_dates[month - 1][0] else zodiac_dates[month - 1][2]

# Function to compute divorce probability based on dataset
def compute_divorce_probability(data):
    relevant_data = divorce_data.copy()
    
    # Ensure all numeric columns are properly converted and handle errors
    for col in ['Monthly_income_partner_man_peso', 'Monthly_income_partner_woman_peso', 'Marriage_duration', 'Num_Children']:
        relevant_data[col] = pd.to_numeric(relevant_data[col], errors='coerce')
    relevant_data = relevant_data.dropna()
    
    # Filter based on salary range
    relevant_data = relevant_data[(relevant_data['Monthly_income_partner_man_peso'] <= data['income_man'] + 5000) &
                                  (relevant_data['Monthly_income_partner_man_peso'] >= data['income_man'] - 5000) &
                                  (relevant_data['Monthly_income_partner_woman_peso'] <= data['income_woman'] + 5000) &
                                  (relevant_data['Monthly_income_partner_woman_peso'] >= data['income_woman'] - 5000)]
    
    # Filter based on marriage duration
    relevant_data = relevant_data[relevant_data['Marriage_duration'] >= data['marriage_duration']]
    
    # Filter based on children
    relevant_data = relevant_data[relevant_data['Num_Children'] == data['children']]
    
    # Calculate zodiac compatibility
    man_zodiac = zodiac_sign(data['dob_man_day'], data['dob_man_month'])
    woman_zodiac = zodiac_sign(data['dob_woman_day'], data['dob_woman_month'])
    zodiac_combination = man_zodiac + woman_zodiac
    compatibility_rate = astro_data[astro_data['Zodiac_combination'] == zodiac_combination]['Compatibility_rate'].values
    compatibility_factor = 1 - (compatibility_rate[0] if len(compatibility_rate) > 0 else 0.5)
    
    # Compute probability
    if not relevant_data.empty:
        divorce_rate = relevant_data.shape[0] / divorce_data.shape[0] * 100
        probability = divorce_rate * compatibility_factor
    else:
        probability = 50 * compatibility_factor  # Default value if no matching data
    
    return min(max(probability, 0), 100)  # Keep within 0-100%

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        try:
            dob_man_day, dob_man_month = map(int, request.form['dob_man'].split('/'))
            dob_woman_day, dob_woman_month = map(int, request.form['dob_woman'].split('/'))
            
            data = {
                'dob_man_day': dob_man_day,
                'dob_man_month': dob_man_month,
                'dob_woman_day': dob_woman_day,
                'dob_woman_month': dob_woman_month,
                'income_man': int(request.form['income_man']),
                'income_woman': int(request.form['income_woman']),
                'marriage_duration': int(request.form['marriage_duration']),
                'children': int(request.form['children'])
            }
            probability = compute_divorce_probability(data)
        except (ValueError, KeyError):
            probability = "Invalid input, please check your values."
        return render_template('index.html', probability=probability)
    return render_template('index.html', probability=None)

if __name__ == '__main__':
    app.run(debug=True)
