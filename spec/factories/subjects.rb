FactoryBot.define do
  factory :subject do
    sequence(:id, &:to_s)
    type { "subject" }
    subject_code { "00" }
    subject_name { "Primary with Mathematics" }
    bursary_amount { nil }
    scholarship { nil }
    early_career_payments { nil }
    subject_knowledge_enhancement_course_available { false }

    trait :english do
      subject_name { "English" }
      subject_code { "Q3" }
    end

    trait :mathematics do
      subject_name { "Mathematics" }
      subject_code { "G1" }
    end

    trait :biology do
      subject_name { "Biology" }
      subject_code { "C1" }
    end

    trait :english_with_primary do
      subject_name { "English with primary" }
      subject_code { "01" }
    end

    trait :modern_languages do
      id { 33 }
      subject_name { "Modern Languages" }
    end

    trait :russian do
      subject_name { "Russian" }
      subject_code { "21" }
    end

    trait :french do
      subject_name { "French" }
      subject_code { "15" }
    end

    trait :japanese do
      subject_name { "Japanese" }
      subject_code { "19" }
    end

    trait :primary do
      subject_name { "Primary" }
      subject_code { "00" }
    end

    trait :design_and_technology do
      subject_name { "Design and technology" }
      subject_code { "DT" }
    end
  end
end
