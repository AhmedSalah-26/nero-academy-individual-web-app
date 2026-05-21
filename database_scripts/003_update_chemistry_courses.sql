-- SQL Script to update existing mock courses to Chemistry courses with YouTube links
-- You can run this script in the Supabase SQL Editor

DO $$
DECLARE
    course_record RECORD;
    counter INT := 0;
    chem_titles TEXT[] := ARRAY[
        'كيمياء للصف الثالث الثانوي - الباب الأول',
        'الكيمياء العضوية - المراجعة النهائية',
        'الكيمياء التحليلية والتوازن الكيميائي',
        'تأسيس كيمياء للمرحلة الثانوية',
        'حل أسئلة بنك المعرفة - كيمياء',
        'كيمياء لغات - Chemistry 3rd Sec',
        'الكيمياء الكهربية - شرح وتدريبات',
        'مراجعة ليلة الامتحان - كيمياء'
    ];
    chem_subtitles TEXT[] := ARRAY[
        'شرح وافي للعناصر الانتقالية مع حل أسئلة النظام الجديد',
        'شرح مبسط للكيمياء العضوية بالكامل مع أهم التفاعلات',
        'فهم عميق للتوازن الكيميائي والتحليل الكمي والكيفي',
        'كورس تأسيسي في الكيمياء لطلاب المرحلة الثانوية',
        'تطبيق عملي وحل أسئلة بنك المعرفة خطوة بخطوة',
        'Comprehensive Chemistry Course for Languages Schools',
        'شرح مفصل للكيمياء الكهربية مع أمثلة وتطبيقات عملية',
        'خلاصة المنهج وتوقعات الامتحان في فيديو واحد'
    ];
    chem_images TEXT[] := ARRAY[
        'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1603126859232-eaefce0f05cb?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1576086213369-97a306d36557?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1581093588401-fbb62a02f120?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1611162617474-5b21e879e113?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'
    ];
    youtube_links TEXT[] := ARRAY[
        'https://www.youtube.com/watch?v=tIjsCGi962E',
        'https://www.youtube.com/watch?v=O5ihXjcIpG8',
        'https://www.youtube.com/watch?v=cbB3DQvGk20',
        'https://www.youtube.com/watch?v=1xW7g42T0pU',
        'https://www.youtube.com/watch?v=2n3x2U0dKmc'
    ];
BEGIN
    FOR course_record IN SELECT id FROM courses LOOP
        UPDATE courses 
        SET 
            title_ar = chem_titles[1 + (counter % array_length(chem_titles, 1))],
            subtitle_ar = chem_subtitles[1 + (counter % array_length(chem_subtitles, 1))],
            thumbnail_url = chem_images[1 + (counter % array_length(chem_images, 1))],
            preview_video_url = youtube_links[1 + (counter % array_length(youtube_links, 1))]
        WHERE id = course_record.id;
        
        counter := counter + 1;
    END LOOP;
END $$;
