import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: Secrets.supabaseURL)!,
    supabaseKey: Secrets.supabaseAnonKey,
    options: .init(auth: .init(emitLocalSessionAsInitialSession: true))
)
