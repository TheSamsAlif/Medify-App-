import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'Dashboard': 'Dashboard',
          'Patients': 'Patients',
          'Alerts': 'Alerts',
          'Analytics': 'Analytics',
          'Settings': 'Settings',
          
          // Caretaker Dashboard
          'Hello, ': 'Hello, ',
          'Good morning!': 'Good morning!',
          'Good afternoon!': 'Good afternoon!',
          'Good evening!': 'Good evening!',
          'Total Patients': 'Total Patients',
          'Avg Adherence': 'Avg Adherence',
          'Active Alerts': 'Active Alerts',
          'Overview of your patients': 'Overview of your patients',
          'Patient Monitoring': 'Patient Monitoring',
          'See All': 'See All',
          'Search patients...': 'Search patients...',
          'No patients found': 'No patients found',
          
          // Caretaker Settings
          'Account': 'Account',
          'Personal Info': 'Personal Info',
          'Update your details': 'Update your details',
          'App Preferences': 'App Preferences',
          'Notifications': 'Notifications',
          'Dark Mode': 'Dark Mode',
          'Language': 'Language',
          'Customize your app experience': 'Customize your app experience',
          'Support & About': 'Support & About',
          'Help Center': 'Help Center',
          'Privacy Policy': 'Privacy Policy',
          'Terms of Service': 'Terms of Service',
          'App Version': 'App Version',
          'Log Out': 'Log Out',
          
          // Patient Analytics
          'Today\'s Taken': 'Today\'s Taken',
          'Today\'s Missed': 'Today\'s Missed',
          'Weekly Adherence Trend': 'Weekly Adherence Trend',
          'Patient Adherence Comparison': 'Patient Adherence Comparison',
          'Medicine Status Distribution': 'Medicine Status Distribution',
          'Key Insights': 'Key Insights',
          'Taken': 'Taken',
          'Missed': 'Missed',
          'Pending': 'Pending',
          'No Meds': 'No Meds',
          'doses': 'doses',
          
          // General
          'English': 'English',
          'Bangla': 'Bangla',
          
          // Patients View
          'Monitor and manage your connected patients': 'Monitor and manage your connected patients',
          'Search patients or conditions...': 'Search patients or conditions...',
          'All': 'All',
          'Excellent (>90%)': 'Excellent (>90%)',
          'Good (70-90%)': 'Good (70-90%)',
          'Needs Attention': 'Needs Attention',
          'General Care': 'General Care',
          'Adherence': 'Adherence',
          'Today\'s Intake Progress': 'Today\'s Intake Progress',
          'taken': 'taken',
          'Last taken: ': 'Last taken: ',
          'Details': 'Details',
          
          // Alerts View
          'Actionable alerts for patient adherence issues': 'Actionable alerts for patient adherence issues',
          'High Priority': 'High Priority',
          'Missed Doses': 'Missed Doses',
          'Late Doses': 'Late Doses',
          'Unread': 'Unread',
          'High': 'High',
          'Read': 'Read',
          'Missed scheduled dose': 'Missed scheduled dose',
          'Mark Read': 'Mark Read',
          
          // Settings View (extra)
          'Manage your caretaker account and preferences': 'Manage your caretaker account and preferences',
          'Caretaker Account': 'Caretaker Account',
          'Your Caretaker Code': 'Your Caretaker Code',
          'Share this code with patients to link them': 'Share this code with patients to link them',
          'Copy Code': 'Copy Code',
          'Connected Patients': 'Connected Patients',
          'Add Patient': 'Add Patient',
          'Overview of patient adherence trends': 'Overview of patient adherence trends',
        },
        'bn_BD': {
          'Dashboard': 'ড্যাশবোর্ড',
          'Patients': 'রোগী',
          'Alerts': 'এলার্ট',
          'Analytics': 'অ্যানালিটিক্স',
          'Settings': 'সেটিংস',
          
          // Caretaker Dashboard
          'Hello, ': 'হ্যালো, ',
          'Good morning!': 'শুভ সকাল!',
          'Good afternoon!': 'শুভ অপরাহ্ন!',
          'Good evening!': 'শুভ সন্ধ্যা!',
          'Total Patients': 'মোট রোগী',
          'Avg Adherence': 'গড় নিয়মানুবর্তিতা',
          'Active Alerts': 'সক্রিয় এলার্ট',
          'Overview of your patients': 'রোগীদের ওভারভিউ',
          'Patient Monitoring': 'রোগী পর্যবেক্ষণ',
          'See All': 'সবগুলো দেখুন',
          'Search patients...': 'রোগী খুঁজুন...',
          'No patients found': 'কোনো রোগী পাওয়া যায়নি',
          
          // Caretaker Settings
          'Account': 'অ্যাকাউন্ট',
          'Personal Info': 'ব্যক্তিগত তথ্য',
          'Update your details': 'তথ্য আপডেট করুন',
          'App Preferences': 'অ্যাপ প্রেফারেন্স',
          'Notifications': 'নোটিফিকেশন',
          'Dark Mode': 'ডার্ক মোড',
          'Language': 'ভাষা',
          'Customize your app experience': 'আপনার অ্যাপ কাস্টমাইজ করুন',
          'Support & About': 'সাপোর্ট এবং পরিচিতি',
          'Help Center': 'হেল্প সেন্টার',
          'Privacy Policy': 'প্রাইভেসি পলিসি',
          'Terms of Service': 'টার্মস অফ সার্ভিস',
          'App Version': 'অ্যাপ ভার্সন',
          'Log Out': 'লগ আউট',
          
          // Patient Analytics
          'Today\'s Taken': 'আজ খাওয়া হয়েছে',
          'Today\'s Missed': 'আজ মিস হয়েছে',
          'Weekly Adherence Trend': 'সাপ্তাহিক মেডিসিন খাওয়ার প্রবণতা',
          'Patient Adherence Comparison': 'রোগীর মেডিসিন খাওয়ার তুলনা',
          'Medicine Status Distribution': 'মেডিসিন স্ট্যাটাস বন্টন',
          'Key Insights': 'মূল বিষয়সমূহ',
          'Taken': 'খাওয়া হয়েছে',
          'Missed': 'মিস হয়েছে',
          'Pending': 'অপেক্ষমান',
          'No Meds': 'কোনো মেডিসিন নেই',
          'doses': 'ডোজ',
          
          // General
          'English': 'ইংরেজি',
          'Bangla': 'বাংলা',

          // Patients View
          'Monitor and manage your connected patients': 'আপনার সাথে যুক্ত রোগীদের পর্যবেক্ষণ করুন',
          'Search patients or conditions...': 'রোগী বা রোগের অবস্থা খুঁজুন...',
          'All': 'সব',
          'Excellent (>90%)': 'অসাধারণ (>৯০%)',
          'Good (70-90%)': 'ভালো (৭০-৯০%)',
          'Needs Attention': 'মনোযোগ প্রয়োজন',
          'General Care': 'সাধারণ যত্ন',
          'Adherence': 'নিয়মানুবর্তিতা',
          'Today\'s Intake Progress': 'আজকের ঔষধ গ্রহণের অগ্রগতি',
          'taken': 'খাওয়া হয়েছে',
          'Last taken: ': 'সর্বশেষ: ',
          'Details': 'বিস্তারিত',
          
          // Alerts View
          'Actionable alerts for patient adherence issues': 'রোগীদের ঔষধ সংক্রান্ত প্রয়োজনীয় এলার্ট',
          'High Priority': 'জরুরি',
          'Missed Doses': 'মিসড ডোজ',
          'Late Doses': 'বিলম্বিত ডোজ',
          'Unread': 'পড়েননি',
          'High': 'জরুরি',
          'Read': 'পড়া হয়েছে',
          'Missed scheduled dose': 'নির্ধারিত ঔষধ মিস করেছেন',
          'Mark Read': 'পড়া হয়েছে',
          
          // Settings View (extra)
          'Manage your caretaker account and preferences': 'আপনার কেয়ারটেকার অ্যাকাউন্ট এবং সেটিংস পরিচালনা করুন',
          'Caretaker Account': 'কেয়ারটেকার অ্যাকাউন্ট',
          'Your Caretaker Code': 'আপনার কেয়ারটেকার কোড',
          'Share this code with patients to link them': 'রোগীদের সাথে যুক্ত হতে এই কোডটি শেয়ার করুন',
          'Copy Code': 'কোড কপি করুন',
          'Connected Patients': 'যুক্ত হওয়া রোগী',
          'Add Patient': 'রোগী যুক্ত করুন',
          'Overview of patient adherence trends': 'রোগীদের ঔষধ গ্রহণের ধারার ওভারভিউ',
        }
      };
}
