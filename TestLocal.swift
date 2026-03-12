
import SwiftUI

struct LocalizationTestView: View {

    @State private var name: String = "Алексей"
    @State private var showAlert = false
	@State private var age = 21
    @State private var message = "Добро пожаловать"
	init() {
		print("Эту строку нужно игнорировать")
		debugPrint("И эту строку нужно игнорировать")
		dump("Ну и эту тоже")
	}

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                Text("Установите порог баланса для уведомлений или настройте автопополнение.")

                Text("Добро пожаловать в приложение")

                Text("Ваше имя: \(name)")
				
				Text("Киличество лет: \(age)!!!")

				// Должен игнорировать
				// "mm_cabinet_troika_auto_payment_balance_threshold": "Порог баланса",
			
                Text("Автопополнение")

                Text("Не уходите в ноль")

                Button("Отправить") {
                    print("Кнопка отправить нажата")
                }

                Button("Удалить аккаунт") {
                    showAlert = true
                }

                TextField("Введите имя", text: $name)

                Toggle("Включить уведомления", isOn: .constant(true))

                Label("Настройки", systemImage: "gear")

                Text("Ошибка загрузки данных")

                Text("Откуда")

                Text("Понятно")
				
                Text("Куда")

                Text("Выйти из аккаунта")

                Image("app_logo")

                Image(systemName: "star.fill")

                Rectangle()
                    .fill(Color("AccentColor"))
                    .frame(height: 50)

                Text("""
                Это многострочный текст
                который используется
                для тестирования
                """)

                Button("Показать сообщение") {
                    message = "Операция выполнена успешно"
                }

                Text(message)
            }
            .navigationTitle("Главный экран")
            .padding()
            .alert("Ошибка", isPresented: $showAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Удалить", role: .destructive) {}
            } message: {
                Text("Вы действительно хотите удалить аккаунт?")
            }
        }
    }
}

#Preview {
    LocalizationTestView()
}
