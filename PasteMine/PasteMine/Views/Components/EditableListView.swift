//
//  EditableListView.swift
//  PasteMine
//
//  Created for privacy settings
//

import SwiftUI

struct EditableListView: View {
    @Binding var items: [String]
    let title: String
    let placeholder: String
    var helpText: String?
    var toggleBinding: Binding<Bool>? = nil
    var toggleLabel: String? = nil
    
    @State private var newItem: String = ""
    @State private var isAdding: Bool = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 列表显示区域
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if items.isEmpty {
                        Text(AppText.Settings.Privacy.emptyList)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(items, id: \.self) { item in
                            HStack {
                                Text(item)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        items.removeAll { $0 == item }
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help(AppText.Common.delete)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                        }
                    }
                }
                .padding(4)
            }
            .frame(maxHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            
            // 添加按钮和输入框
            if isAdding {
                HStack(spacing: 6) {
                    TextField(placeholder, text: $newItem)
                        .textFieldStyle(.plain)
                        .font(.caption)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.1))
                        )
                        .focused($isInputFocused)
                        .onSubmit {
                            addItem()
                        }
                    
                    Button(action: {
                        addItem()
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                    .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isAdding = false
                            newItem = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: 8) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isAdding = true
                            isInputFocused = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text(AppText.Settings.Privacy.addType)
                        }
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                    
                    if let helpText = helpText {
                        Text(helpText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if let toggleBinding = toggleBinding {
                        HStack(spacing: 4) {
                            if let toggleLabel = toggleLabel {
                                Text(toggleLabel)
                                    .font(.caption2)
                                    .foregroundStyle(.primary)
                            }
                            
                            Toggle("", isOn: toggleBinding)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .controlSize(.mini)
                        }
                    }
                }
            }
        }
    }
    
    private func addItem() {
        let trimmedItem = newItem.trimmingCharacters(in: .whitespaces)
        
        // 验证：不能为空，不能重复
        guard !trimmedItem.isEmpty else { return }
        guard !items.contains(trimmedItem) else {
            // 已存在，给予反馈
            NSSound.beep()
            return
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            items.append(trimmedItem)
            newItem = ""
            isAdding = false
        }
    }
}

#Preview {
    @Previewable @State var testItems = ["Safari", "Chrome", "1Password"]
    
    EditableListView(
        items: $testItems,
        title: "测试列表",
        placeholder: "输入项目名称",
        helpText: "这是帮助文字"
    )
    .padding()
    .frame(width: 300)
}
